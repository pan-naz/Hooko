import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:hooko_v20/models/analysis_result.dart';
import 'package:hooko_v20/services/video_processor.dart';
import 'package:hooko_v20/services/niche_service.dart';
import 'package:hooko_v20/supabase/supabase_config.dart';


// Keep console output high-signal by default.
// Enable verbose traces with: --dart-define=HOOKO_VERBOSE_LOGS=true
const bool _verboseLogs = bool.fromEnvironment('HOOKO_VERBOSE_LOGS', defaultValue: false);



/// Exception thrown when analysis is cancelled
class AnalysisCancelledException implements Exception {
  final String message;
  AnalysisCancelledException([this.message = 'Analysis cancelled']);
  @override
  String toString() => message;
}

/// Token to track and trigger cancellation of analysis
class AnalysisCancellationToken {
  bool _isCancelled = false;
  String? _uploadedFilePath;
  
  bool get isCancelled => _isCancelled;
  
  /// Set the uploaded file path for cleanup on cancellation
  void setUploadedFilePath(String? path) {
    _uploadedFilePath = path;
  }
  
  /// Cancel the analysis and cleanup any uploaded files
  Future<void> cancel() async {
    if (_isCancelled) return;
    _isCancelled = true;
    if (_verboseLogs) debugPrint('AnalysisCancellationToken: Cancellation requested');
    
    // Cleanup uploaded file if exists
    if (_uploadedFilePath != null) {
      try {
        await SupabaseConfig.client.storage.from('Videos').remove([_uploadedFilePath!]);
        if (_verboseLogs) debugPrint('AnalysisCancellationToken: Cleaned up uploaded video: $_uploadedFilePath');
      } catch (e) {
        debugPrint('AnalysisCancellationToken: Cleanup failed: $e');
      }
      _uploadedFilePath = null;
    }
  }
  
  /// Check if cancelled and throw if so
  void throwIfCancelled() {
    if (_isCancelled) {
      throw AnalysisCancelledException();
    }
  }
}

/// Service for analyzing videos using Gemini AI via Supabase Edge Function
class AnalysisService {
  static const String _historyKey = 'analysis_history';
  static const String _edgeFunctionUrl = 'analyze-video';
  static const String _storageBucket = 'Videos';
  static const _uuid = Uuid();
  
  /// Analyze a video and return the analysis result
  /// 
  /// Flow:
  /// 1. Convert video to MP4, 720p, 30fps
  /// 2. Upload to Supabase Storage
  /// 3. Call Edge Function with video path
  /// 4. Edge Function calls Gemini AI
  /// 5. Edge Function deletes video and returns analysis
  /// 
  /// Pass [cancellationToken] to enable cancellation when app closes or user navigates away.
  static Future<AnalysisResult> analyzeVideo(
    AssetEntity videoAsset, {
    Function(String status, double progress)? onProgress,
    AnalysisCancellationToken? cancellationToken,
  }) async {
    String? uploadedFilePath;
    
    try {
      // Check cancellation before starting
      cancellationToken?.throwIfCancelled();
      
      // Step 1: Process video - convert to MP4, 720p, 30fps
      onProgress?.call('Processing video...', 0.05);
      
      VideoProcessingResult processingResult;
      try {
        processingResult = await VideoProcessor.processVideo(
          videoAsset,
          onProgress: (status, progress) {
            // Compression takes 5-30% of total progress
            // VideoProcessor reports 0.1-0.5 for compression, 0.6-1.0 for post-processing
            // Map: 0.0-0.5 (compression) -> 0.05-0.25, 0.5-1.0 (post) -> 0.25-0.30
            final mappedProgress = progress <= 0.5
                ? 0.05 + (progress * 0.4)  // 0.05 to 0.25 during compression
                : 0.25 + ((progress - 0.5) * 0.1);  // 0.25 to 0.30 post-compression
            onProgress?.call(status, mappedProgress);
          },
        );
      } catch (e) {
        final errorString = e.toString().toLowerCase();
        
        // If compression failed after retries, don't fall back to raw file
        // Let the error propagate so user sees "Try Again" button
        if (errorString.contains('compression_failed')) {
          if (_verboseLogs) debugPrint('AnalysisService: Compression failed after 2 attempts, not uploading raw file');
          rethrow;
        }
        
        // If video is too heavy even after 360p compression, show user-friendly error
        if (errorString.contains('video_too_heavy')) {
          if (_verboseLogs) debugPrint('AnalysisService: Video too heavy even after 360p compression');
          rethrow;
        }
        
        // For other errors (file access issues), try fallback
        debugPrint('AnalysisService: Native processing failed, trying fallback: $e');
        processingResult = await VideoProcessor.processVideoFallback(
          videoAsset,
          onProgress: (status, progress) {
            final mappedProgress = progress <= 0.5
                ? 0.05 + (progress * 0.4)
                : 0.25 + ((progress - 0.5) * 0.1);
            onProgress?.call(status, mappedProgress);
          },
        );
      }
      
      // Check cancellation after processing (before upload)
      cancellationToken?.throwIfCancelled();
      
      if (!processingResult.isValid) {
        throw Exception('Failed to process video');
      }
      
      if (_verboseLogs) {
        debugPrint('AnalysisService: Video processed - ${processingResult.sizeMB.toStringAsFixed(2)} MB, ${processingResult.durationSeconds}s');
      }
      
      // Step 2: Upload to Supabase Storage
      // Report 0.30 = compression done, upload starting (step 0 still active in UI)
      onProgress?.call('Uploading video...', 0.30);
      
      // Check cancellation before upload (this is the last safe point before costs)
      cancellationToken?.throwIfCancelled();
      
      final videoId = _uuid.v4();
      uploadedFilePath = 'temp/$videoId.mp4';
      
      // Register uploaded file path with cancellation token for cleanup
      cancellationToken?.setUploadedFilePath(uploadedFilePath);
      
      await SupabaseConfig.client.storage.from(_storageBucket).uploadBinary(
        uploadedFilePath,
        processingResult.videoBytes,
        fileOptions: const FileOptions(
          contentType: 'video/mp4',
          upsert: true,
        ),
      );
      
      // Report 0.35 = upload complete, step 0 done (triggers UI to move to step 1)
      onProgress?.call('Video uploaded', 0.35);
      
      // Check cancellation after upload, before expensive AI call
      // This is CRITICAL - after this point, the edge function will be called
      // and Gemini tokens will be consumed
      cancellationToken?.throwIfCancelled();
      
      // Step 3: Call Supabase Edge Function with SSE streaming
      onProgress?.call('Analyzing with AI...', 0.5);
      
      // Build SSE request URL
      final functionUrl = '${SupabaseConfig.supabaseUrl}/functions/v1/$_edgeFunctionUrl';
      
      // Make SSE streaming request
      final sseRequest = http.Request('POST', Uri.parse(functionUrl));
      sseRequest.headers['Content-Type'] = 'application/json';
      sseRequest.headers['apikey'] = SupabaseConfig.anonKey;
      
      // Add Authorization header with user's JWT token (required since verify_jwt = true)
      final session = SupabaseConfig.client.auth.currentSession;
      if (session != null) {
        sseRequest.headers['Authorization'] = 'Bearer ${session.accessToken}';
      }
      
      sseRequest.body = jsonEncode({
        'video_path': uploadedFilePath,
        'video_duration_seconds': processingResult.durationSeconds,
        'bucket': _storageBucket,
      });
      
      final httpClient = http.Client();
      Map<String, dynamic>? data;
      
      try {
        final response = await httpClient.send(sseRequest);
        
        if (response.statusCode != 200) {
          throw Exception('Analysis failed: HTTP ${response.statusCode}');
        }
        
        // Parse SSE stream
        final completer = Completer<Map<String, dynamic>>();
        final buffer = StringBuffer();
        
        response.stream
            .transform(utf8.decoder)
            .listen(
          (chunk) {
            buffer.write(chunk);
            
            // Process complete SSE events from buffer
            final content = buffer.toString();
            final events = content.split('\n\n');
            
            // Keep incomplete event in buffer
            if (!content.endsWith('\n\n') && events.isNotEmpty) {
              buffer.clear();
              buffer.write(events.removeLast());
            } else {
              buffer.clear();
            }
            
            for (final eventStr in events) {
              if (eventStr.trim().isEmpty) continue;
              
              // Skip keep-alive comments
              if (eventStr.startsWith(':')) continue;
              
              // Parse SSE event
              String? eventType;
              String? eventData;
              
              for (final line in eventStr.split('\n')) {
                if (line.startsWith('event: ')) {
                  eventType = line.substring(7).trim();
                } else if (line.startsWith('data: ')) {
                  eventData = line.substring(6);
                }
              }
              
              if (eventType != null && eventData != null) {
                try {
                  final parsedData = jsonDecode(eventData);
                  
                  switch (eventType) {
                    case 'progress':
                      // Map SSE progress to UI progress (35-95%)
                      final sseProgress = (parsedData['progress'] as num?)?.toDouble() ?? 0;
                      final mappedProgress = 0.35 + (sseProgress / 100) * 0.6;
                      onProgress?.call(parsedData['status'] ?? 'Processing...', mappedProgress.clamp(0.35, 0.95));
                      if (_verboseLogs) {
                        debugPrint('AnalysisService: SSE progress - ${parsedData['status']}: ${sseProgress.toInt()}%');
                      }
                      break;
                    case 'complete':
                      if (_verboseLogs) debugPrint('AnalysisService: SSE complete received');
                      if (!completer.isCompleted) {
                        completer.complete(parsedData as Map<String, dynamic>);
                      }
                      break;
                    case 'error':
                      debugPrint('AnalysisService: SSE error - ${parsedData['error']}');
                      if (!completer.isCompleted) {
                        completer.completeError(Exception(parsedData['error'] ?? 'Analysis failed'));
                      }
                      break;
                  }
                } catch (e) {
                  debugPrint('AnalysisService: Failed to parse SSE event: $e');
                }
              }
            }
          },
          onDone: () {
            if (!completer.isCompleted) {
              completer.completeError(Exception('SSE stream ended unexpectedly'));
            }
          },
          onError: (error) {
            if (!completer.isCompleted) {
              completer.completeError(error);
            }
          },
          cancelOnError: true,
        );
        
        // Wait for analysis to complete
        data = await completer.future;
      } finally {
        httpClient.close();
      }
      
      // Note: Once edge function is called, we can't cancel the AI processing
      // but we can still avoid saving/processing results if cancelled
      
      onProgress?.call('Processing results...', 0.95);
      
      // Check cancellation before processing results
      cancellationToken?.throwIfCancelled();
      
      // Debug: Log hook alternatives to diagnose missing fields
      if (_verboseLogs && data['hook_alternatives'] != null) {
        final hooks = data['hook_alternatives'] as List;
        for (int i = 0; i < hooks.length; i++) {
          final hook = hooks[i] as Map<String, dynamic>;
          debugPrint('AnalysisService: Hook ${i + 1} - caption: "${hook['suggested_caption'] ?? 'MISSING'}"');
          debugPrint('AnalysisService: Hook ${i + 1} - hashtags: ${hook['suggested_hashtags'] ?? 'MISSING'}');
          debugPrint('AnalysisService: Hook ${i + 1} - audio_techniques: ${hook['audio_techniques'] ?? 'MISSING'}');
          debugPrint('AnalysisService: Hook ${i + 1} - visual_techniques: ${hook['visual_techniques'] ?? 'MISSING'}');
        }
      }
      
      // Add metadata
      data['id'] = videoId;
      data['video_id'] = videoId;
      data['created_at'] = DateTime.now().toIso8601String();
      
      // Add thumbnail from processing result
      if (processingResult.thumbnailBytes != null) {
        data['thumbnail_base64'] = base64Encode(processingResult.thumbnailBytes!);
      }
      
      var result = AnalysisResult.fromJson(data);
      
      // Edge function already provides niche data (name, category, benchmarks)
      // Only fetch from NicheService as fallback if missing
      if (result.nicheName == null || result.nicheCategory == null) {
        try {
          final niche = await NicheService().getNicheBySlug(result.nicheSlug);
          result = result.copyWith(
            nicheName: result.nicheName ?? niche.name,
            nicheCategory: result.nicheCategory ?? niche.category,
            benchmark: result.benchmark == 70 ? niche.avgHookScore : result.benchmark,
            industryBenchmarkTiktok: result.industryBenchmarkTiktok ?? niche.tiktokEngagement,
            industryBenchmarkInstagram: result.industryBenchmarkInstagram ?? niche.instagramEngagement,
            industryBenchmarkYoutube: result.industryBenchmarkYoutube ?? niche.youtubeEngagement,
            industryBenchmarkAvg: result.industryBenchmarkAvg ?? niche.avgEngagement,
          );
          if (_verboseLogs) debugPrint('AnalysisService: Niche data fetched as fallback - ${niche.name}');
        } catch (e) {
          debugPrint('AnalysisService: Could not fetch niche fallback data: $e');
        }
      } else {
        if (_verboseLogs) {
          debugPrint('AnalysisService: Using niche data from edge function - ${result.nicheName}, TikTok: ${result.industryBenchmarkTiktok}%, Avg: ${result.industryBenchmarkAvg}%');
        }
      }
      
      // Step 4: Save to history
      onProgress?.call('Saving to history...', 0.95);
      await _saveToHistory(result);
      
      // Step 5: Fallback cleanup - delete video from storage
      // Edge function should delete, but we do it here too as fallback
      try {
        await SupabaseConfig.client.storage.from(_storageBucket).remove([uploadedFilePath]);
        if (_verboseLogs) debugPrint('AnalysisService: Fallback cleanup - deleted video: $uploadedFilePath');
      } catch (cleanupError) {
        // Silent fail - edge function may have already deleted it
        if (_verboseLogs) debugPrint('AnalysisService: Fallback cleanup skipped (already deleted or error): $cleanupError');
      }
      
      uploadedFilePath = null;
      cancellationToken?.setUploadedFilePath(null);
      
      onProgress?.call('Complete!', 1.0);
      if (_verboseLogs) debugPrint('AnalysisService: Analysis complete, score: ${result.overallScore}');
      
      return result;
    } on AnalysisCancelledException {
      if (_verboseLogs) debugPrint('AnalysisService: Analysis was cancelled');
      // Cleanup is handled by the cancellation token
      rethrow;
    } catch (e) {
      debugPrint('AnalysisService: Error analyzing video: $e');
      
      // Cleanup: try to delete uploaded video if it exists
      if (uploadedFilePath != null) {
        try {
          await SupabaseConfig.client.storage.from(_storageBucket).remove([uploadedFilePath]);
          debugPrint('AnalysisService: Cleaned up uploaded video');
        } catch (cleanupError) {
          debugPrint('AnalysisService: Cleanup failed: $cleanupError');
        }
      }
      
      rethrow;
    }
  }
  
  /// History retention period in days
  static const int _historyRetentionDays = 365;
  
  /// Save analysis result to local history
  static Future<void> _saveToHistory(AnalysisResult result) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList(_historyKey) ?? [];
      
      // Add new result at the beginning
      historyJson.insert(0, result.toJsonString());
      
      await prefs.setStringList(_historyKey, historyJson);
      if (_verboseLogs) debugPrint('AnalysisService: Saved to history, total: ${historyJson.length}');
    } catch (e) {
      debugPrint('AnalysisService: Failed to save to history: $e');
    }
  }
  
  /// Get analysis history from local storage
  /// This is the ONLY place where expired entries (>365 days) are cleaned up
  static Future<List<AnalysisResult>> getHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList(_historyKey) ?? [];
      final cutoffDate = DateTime.now().subtract(const Duration(days: _historyRetentionDays));
      
      final results = <AnalysisResult>[];
      final validJsonEntries = <String>[];
      bool needsCleanup = false;
      
      for (final json in historyJson) {
        try {
          final result = AnalysisResult.fromJsonString(json);
          if (result.createdAt.isAfter(cutoffDate)) {
            results.add(result);
            validJsonEntries.add(json);
          } else {
            needsCleanup = true; // Found expired entry
          }
        } catch (e) {
          debugPrint('AnalysisService: Failed to parse history item: $e');
          needsCleanup = true; // Found corrupted entry
        }
      }
      
      // Save cleaned list if we removed any expired/corrupted entries
      if (needsCleanup) {
        await prefs.setStringList(_historyKey, validJsonEntries);
        if (_verboseLogs) debugPrint('AnalysisService: Cleaned up expired history, remaining: ${results.length}');
      }
      
      return results;
    } catch (e) {
      debugPrint('AnalysisService: Failed to load history: $e');
      return [];
    }
  }
  
  /// Clear analysis history
  static Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_historyKey);
      if (_verboseLogs) debugPrint('AnalysisService: History cleared');
    } catch (e) {
      debugPrint('AnalysisService: Failed to clear history: $e');
    }
  }
  
  /// Delete a specific analysis from history
  static Future<void> deleteFromHistory(String analysisId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList(_historyKey) ?? [];

      // IMPORTANT: This method is sometimes triggered as a “fire-and-forget” call
      // from the UI. Even when not awaited, heavy work here still runs on the
      // main isolate and can cause visible jank.
      //
      // Optimization: avoid JSON-decoding *every* history item just to find the
      // target id. Most entries contain an "id" field; a fast regex check is
      // enough for deletion.
      final idRegex = RegExp('"id"\\s*:\\s*"${RegExp.escape(analysisId)}"');
      final before = historyJson.length;
      historyJson.removeWhere((json) => idRegex.hasMatch(json));

      // Fallback: if we didn’t match anything (older/corrupted formats), fall
      // back to the slower but safer decode path.
      if (historyJson.length == before) {
        historyJson.removeWhere((json) {
          try {
            final result = AnalysisResult.fromJsonString(json);
            return result.id == analysisId;
          } catch (_) {
            return false;
          }
        });
      }
      
      await prefs.setStringList(_historyKey, historyJson);
      if (_verboseLogs) debugPrint('AnalysisService: Deleted analysis $analysisId from history');
    } catch (e) {
      debugPrint('AnalysisService: Failed to delete from history: $e');
    }
  }
}
