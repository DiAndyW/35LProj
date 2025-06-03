// In ../models/MoodPost.js
import mongoose from 'mongoose';

const moodPostSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  emotion: {
    name: String,
    // attributes: { pleasantness: Number, intensity: Number, ... }
  },
  reason: String,
  location: {
    landmarkName: String,
    coordinates: { // GeoJSON Point
      type: { type: String, enum: ['Point'], required: true, default: 'Point' },
      coordinates: { type: [Number], required: true } // [longitude, latitude]
    }
  },
  privacy: { type: String, enum: ['public', 'friends', 'private'], default: 'public', index: true },
  timestamp: { type: Date, default: Date.now, index: true },
  isAnonymous: { type: Boolean, default: false },
  // ... other fields
}, { timestamps: true });

moodPostSchema.index({ 'location.coordinates': '2dsphere' }); // VERY IMPORTANT
moodPostSchema.index({ privacy: 1, timestamp: -1 }); // Good for combined filtering

export default mongoose.model('MoodPost', moodPostSchema);