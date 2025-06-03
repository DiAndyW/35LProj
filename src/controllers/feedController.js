import MoodCheckIn from '../models/CheckIn.js';

export const getFeedCheckIns = async (req, res) => {
    try {

        // sort by hottest (most liked) or recent (timestamp)
        const sortQuery = req.query.sort || 'timestamp';
        if (sortQuery !== 'timestamp' && sortQuery !== 'hottest') {
            return res.status(400).json({ error: 'Invalid sort method. Use "timestamp" or "hottest".' });
        }
        const sortMethod = (sortQuery === 'hottest' ? { 'likes.count': -1 } : { timestamp: -1 });

        // Parse skip and limit from query, with defaults
        const skip = Math.max(parseInt(req.query.skip, 10) || 0, 0);
        const limit = Math.min(parseInt(req.query.limit, 10) || 20, 100);

        const checkIns = await MoodCheckIn.find({ privacy: 'public' })
            .sort(sortMethod)
            .skip(skip)
            .limit(limit);

        const responseData = checkIns.map(checkIn => checkIn.displayData);

        res.json(responseData);
    } catch (error) {
        res.status(500).json({ error: 'Failed to fetch feed', details: error.message });
    }
}