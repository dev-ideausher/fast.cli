//Copyright 2020 Pedro Bissonho
//
//Licensed under the Apache License, Version 2.0 (the "License");
//you may not use this file except in compliance with the License.
//You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
//Unless required by applicable law or agreed to in writing, software
//distributed under the License is distributed on an "AS IS" BASIS,
//WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//See the License for the specific language governing permissions and
//limitations under the License.

import 'dart:async';

/// A simple in-memory cache with expiration support.
/// 
/// Useful for caching expensive operations like YAML parsing or API calls.
class Cache<K, V> {
  final Map<K, _CacheEntry<V>> _cache = {};
  final Duration? defaultTTL;

  /// Creates a cache with an optional default TTL.
  /// 
  /// [defaultTTL] - Default time-to-live for cached entries. If null, entries
  ///                never expire (unless manually cleared).
  Cache({this.defaultTTL});

  /// Gets a value from the cache.
  /// 
  /// Returns null if the key doesn't exist or has expired.
  V? get(K key) {
    final entry = _cache[key];
    if (entry == null) return null;

    if (entry.isExpired) {
      _cache.remove(key);
      return null;
    }

    return entry.value;
  }

  /// Gets a value from the cache, or computes it if not present.
  /// 
  /// [key] - The cache key.
  /// [compute] - Function to compute the value if not cached.
  /// [ttl] - Optional TTL for this specific entry (overrides defaultTTL).
  /// 
  /// Returns the cached or computed value.
  Future<V> getOrCompute(
    K key,
    Future<V> Function() compute, {
    Duration? ttl,
  }) async {
    final cached = get(key);
    if (cached != null) return cached;

    final value = await compute();
    put(key, value, ttl: ttl);
    return value;
  }

  /// Puts a value into the cache.
  /// 
  /// [key] - The cache key.
  /// [value] - The value to cache.
  /// [ttl] - Optional TTL for this entry (overrides defaultTTL).
  void put(K key, V value, {Duration? ttl}) {
    final expiresAt = (ttl ?? defaultTTL) != null
        ? DateTime.now().add(ttl ?? defaultTTL!)
        : null;

    _cache[key] = _CacheEntry(value, expiresAt);
  }

  /// Removes a value from the cache.
  void remove(K key) {
    _cache.remove(key);
  }

  /// Clears all cached values.
  void clear() {
    _cache.clear();
  }

  /// Checks if a key exists in the cache (and hasn't expired).
  bool containsKey(K key) {
    return get(key) != null;
  }

  /// Gets the number of cached entries.
  int get size => _cache.length;

  /// Removes expired entries from the cache.
  void evictExpired() {
    _cache.removeWhere((key, entry) => entry.isExpired);
  }
}

/// Internal cache entry with expiration tracking.
class _CacheEntry<V> {
  final V value;
  final DateTime? expiresAt;

  _CacheEntry(this.value, this.expiresAt);

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }
}

