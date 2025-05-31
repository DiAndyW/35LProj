import MoodCheckIn from '../models/CheckIn.js';

export const getFeedCheckIns = async (req, res) => {
    try {
        const checkIns = await MoodCheckIn.find({ privacy: 'public' })
            .sort({ timestamp: -1 })
            .limit(20);

        // Map each check-in to its displayData
        const responseData = checkIns.map(checkIn => checkIn.displayData);

        res.json(responseData);
    } catch (error) {
        res.status(500).json({ error: 'Failed to fetch feed', details: error.message });
    }
}