import MoodCheckIn from '../models/CheckIn.js';

export const getFeedCheckIns = async (req, res) => {
    try {

        // Parse skip and limit from query, with defaults
        const skip = Math.max(parseInt(req.query.skip, 10) || 0, 0);
        const limit = Math.min(parseInt(req.query.limit, 10) || 20, 100);

        const checkIns = await MoodCheckIn.find({ privacy: 'public' })
            .sort({ timestamp: -1 })
            .skip(skip)
            .limit(limit);

        const responseData = checkIns.map(checkIn => checkIn.displayData);

        res.json(responseData);
    } catch (error) {
        res.status(500).json({ error: 'Failed to fetch feed', details: error.message });
    }
}