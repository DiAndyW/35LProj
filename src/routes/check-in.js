import express from 'express';
import MoodCheckIn from '../models/CheckIn.js';

const router = express.Router();

// POST - Create a new check-in
router.post('/checkin', async (req, res) => {
  try {
    const {
      userId,
      emotion,
      reason,
      people,
      activities,
      location,
      privacy
    } = req.body;

    // Validate required fields
    if (!userId || !emotion || !emotion.name) {
      return res.status(400).json({ error: 'Required fields missing' });
    }

    const newCheckIn = new MoodCheckIn({
      userId,
      emotion: {
        name: emotion.name,
        attributes: emotion.attributes || {}
      },
      reason,
      people: people || [],
      activities: activities || [],
      location: location || { name: null, coordinates: null, isShared: false },
      privacy: privacy || 'private',
      timestamp: new Date()
    });

    const savedCheckIn = await newCheckIn.save();
    res.status(201).json(savedCheckIn.displayData);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// GET - Retrieve a user's check-ins
router.get('/checkin/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    const { limit = 10, skip = 0, privacy } = req.query;
    
    const query = { userId };
    
    // Add privacy filter if specified
    if (privacy) {
      query.privacy = privacy;
    }
    
    const checkIns = await MoodCheckIn.find(query)
      .sort({ timestamp: -1 })
      .skip(Number(skip))
      .limit(Number(limit));
      
    res.json(checkIns.map(checkIn => checkIn.displayData));
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// GET - Retrieve a specific check-in by ID
router.get('/checkin/detail/:id', async (req, res) => {
  try {
    const checkIn = await MoodCheckIn.findById(req.params.id);
    
    if (!checkIn) {
      return res.status(404).json({ error: 'Check-in not found' });
    }
    
    res.json(checkIn.displayData);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// DELETE - Remove a check-in
router.delete('/checkin/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { userId } = req.body; // For authorization
    
    const checkIn = await MoodCheckIn.findById(id);
    
    if (!checkIn) {
      return res.status(404).json({ error: 'Check-in not found' });
    }
    
    // Verify the check-in belongs to the user
    if (checkIn.userId.toString() !== userId) {
      return res.status(403).json({ error: 'Unauthorized' });
    }
    
    await MoodCheckIn.findByIdAndDelete(id);
    res.json({ message: 'Check-in deleted successfully' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

export default router;