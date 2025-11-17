// POST /api/webhook?days=30
// Returns aggregated download statistics in stats.json format
// Requires x-webhook-secret header for authentication

import { Redis } from '@upstash/redis';

const redis = Redis.fromEnv();

export default async function handler(req, res) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  // Check webhook secret
  const secret = req.headers['x-webhook-secret'];
  if (secret !== process.env.WEBHOOK_SECRET) {
    return res.status(401).json({ error: 'Unauthorized' });
  }

  const days = parseInt(req.query.days || '30');
  const cutoffTime = Date.now() - (days * 24 * 60 * 60 * 1000);
  const weekAgo = Date.now() - (7 * 24 * 60 * 60 * 1000);
  const monthAgo = Date.now() - (30 * 24 * 60 * 60 * 1000);

  try {
    // Get all asset keys using SCAN (Upstash Redis requirement)
    const keys = [];
    let cursor = 0;
    let scanIterations = 0;
    
    do {
      const result = await redis.scan(cursor, { match: 'events:*', count: 100 });
      
      // Upstash Redis SCAN returns [cursor, keys[]] array or {cursor, keys}
      let newCursor, foundKeys;
      if (Array.isArray(result)) {
        [newCursor, foundKeys] = result;
      } else if (result && typeof result === 'object') {
        newCursor = result.cursor ?? result[0];
        foundKeys = result.keys ?? result[1] ?? [];
      } else {
        newCursor = result;
        foundKeys = [];
      }
      
      // Normalize cursor to number
      if (typeof newCursor === 'string') {
        cursor = newCursor === '0' ? 0 : parseInt(newCursor, 10);
      } else {
        cursor = newCursor || 0;
      }
      
      if (foundKeys && Array.isArray(foundKeys) && foundKeys.length > 0) {
        keys.push(...foundKeys);
      }
      
      scanIterations++;
      // Safety: limit iterations to prevent infinite loops
      if (scanIterations > 1000) {
        console.error('SCAN exceeded max iterations', { cursor, keysFound: keys.length });
        break;
      }
      
      // SCAN is complete when cursor is 0
    } while (cursor !== 0);
    
    console.log(`SCAN found ${keys.length} keys:`, keys.slice(0, 10));
    
    const stats = {};
    
    for (const key of keys) {
      try {
        const assetId = key.replace('events:', '');
        console.log(`Processing: ${key} -> ${assetId}`);
        
        // Get events using Sorted Set (efficient range queries by timestamp)
        // Events are stored as timestamps with timestamp as score
        // @upstash/redis uses zrange(key, min, max, {byScore: true}) instead of zrangebyscore
        const allEventTimestamps = await redis.zrange(key, cutoffTime, '+inf', { byScore: true });
        
        if (!allEventTimestamps || !Array.isArray(allEventTimestamps) || allEventTimestamps.length === 0) {
          continue;
        }
        
        // Convert string timestamps to numbers
        const allEvents = allEventTimestamps
          .map(ts => typeof ts === 'string' ? parseInt(ts, 10) : ts)
          .filter(ts => !isNaN(ts));
        
        if (allEvents.length === 0) {
          continue;
        }
        
        // Aggregate statistics using efficient filtering
        const weekCount = allEvents.filter(ts => ts >= weekAgo).length;
        const monthCount = allEvents.filter(ts => ts >= monthAgo).length;
        
        console.log(`  -> Found ${allEvents.length} events (week: ${weekCount}, month: ${monthCount})`);
        
        stats[assetId] = {
          total: allEvents.length,
          last_week: weekCount,
          last_month: monthCount
        };
      } catch (e) {
        console.error(`Error processing key ${key}:`, e);
        continue;
      }
    }

    return res.status(200).json({
      downloads: stats,
      updated_at: new Date().toISOString()
    });

  } catch (error) {
    console.error('Webhook error:', error);
    return res.status(500).json({ 
      error: 'Internal server error',
      message: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
}

