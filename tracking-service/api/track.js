// GET /api/track?asset=author:id@version&user_id=<optional>
// Tracks asset download with protection against spam (max 1 per 24h per user)

import { Redis } from '@upstash/redis';

const redis = Redis.fromEnv();

function generateUserId(req) {
  const ip = req.headers['x-forwarded-for'] 
    || req.headers['x-real-ip'] 
    || req.connection?.remoteAddress 
    || 'unknown';
  const ua = req.headers['user-agent'] || 'unknown';
  return Buffer.from(ip + ua).toString('base64').substring(0, 16);
}

export default async function handler(req, res) {
  // CORS headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'GET') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const { asset, user_id } = req.query;

  if (!asset) {
    return res.status(400).json({ error: 'Missing asset parameter' });
  }

  const clientId = user_id || generateUserId(req);
  const protectionKey = `track:${asset}:${clientId}`;
  const oneDaySeconds = 24 * 60 * 60;
  const now = Date.now();
  
  try {
    // Check if already tracked in last 24 hours
    const lastTrack = await redis.get(protectionKey);
    if (lastTrack) {
      const timeSinceLastTrack = (now - parseInt(lastTrack)) / 1000;
      if (timeSinceLastTrack < oneDaySeconds) {
        const hoursLeft = Math.ceil((oneDaySeconds - timeSinceLastTrack) / 3600);
        return res.status(200).json({ 
          tracked: false, 
          reason: 'already_tracked_today',
          next_track_in_hours: hoursLeft
        });
      }
    }

    // Save protection key with 24h TTL
    await redis.set(protectionKey, now.toString(), { ex: oneDaySeconds });

    // Store event in Redis Sorted Set (timestamp as score for efficient range queries)
    const eventKey = `events:${asset}`;
    const eventValue = now.toString(); // Use timestamp as both score and value
    
    // Add event with timestamp as score (enables efficient time-based filtering)
    // @upstash/redis zadd syntax: zadd(key, {score, member})
    await redis.zadd(eventKey, { score: now, member: eventValue });
    
    // Remove events older than 30 days (keep only recent events)
    const thirtyDaysAgo = now - (30 * 24 * 60 * 60 * 1000);
    await redis.zremrangebyscore(eventKey, 0, thirtyDaysAgo);
    
    // Set TTL on the sorted set (30 days)
    await redis.expire(eventKey, 30 * 24 * 60 * 60);

    return res.status(200).json({ 
      tracked: true,
      asset: asset,
      timestamp: new Date(now).toISOString()
    });

  } catch (error) {
    console.error('Tracking error:', error);
    console.error('Error details:', {
      message: error.message,
      stack: error.stack,
      name: error.name
    });
    // Fail silently - don't break user experience
    return res.status(500).json({ 
      error: 'Internal server error', 
      tracked: false,
      message: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
}

