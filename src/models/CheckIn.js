import mongoose from 'mongoose';

const { Schema } = mongoose;

const moodCheckInSchema = new Schema({
  // Basic user information
  userId: {
    type: Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },

  // Emotion data (from original Mood schema)
  emotion: {
    name: {
      type: String,
      required: true,
    },
    attributes: {
      pleasantness: {
        type: Number,
        default: 0,
      },
      intensity: {
        type: Number,
        default: 0,
      },
      clarity: {
        type: Number,
        default: 0,
      },
      control: {
        type: Number,
        default: 0,
      },
    }
  },

  // User input content 
  reason: {
    type: String,
    maxlength: 500,
  },

  // Social context
  people: [{
    name: {
      type: String,
      required: true
    },
    userId: {
      type: Schema.Types.ObjectId,
      ref: 'User'
    }
  }],

  // Activities
  activities: [{
    name: {
      type: String,
      required: true
    },
    isCustom: {
      type: Boolean,
      default: false
    }
  }],

  // Location data
  location: {
    name: {
      type: String,
      default: null
    },
    coordinates: {
      type: [Number],
      validate: v => v == null || v.length === 2,
      default: null
    },
    isShared: {
      type: Boolean,
      default: false
    }
  },

  // Privacy settings
  privacy: {
    type: String,
    enum: ['friends', 'public', 'private'],
    default: 'private',
  },

  // Timestamp
  timestamp: {
    type: Date,
    default: Date.now,
  },

  // Backwards compatibility fields that map to new structure
  get isAnonymous() {
    return this.privacy === 'private';
  },

  // Original Mood structure for complete backwards compatibility
  get mood() {
    return {
      label: this.emotion.name,
      attributes: this.emotion.attributes,
      note: this.reason,
      time: this.timestamp
    };
  },
  set mood(value) {
    if (value.label) this.emotion.name = value.label;
    if (value.attributes) this.emotion.attributes = value.attributes;
    if (value.note !== undefined) this.reason = value.note;
    if (value.time) this.timestamp = value.time;
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true, getters: true },
  toObject: { virtuals: true, getters: true }
});

// Virtual fields for frontend consumption
moodCheckInSchema.virtual('displayData').get(function() {
  return {
    id: this._id,
    userId: this.userId,
    emotion: {
      name: this.emotion.name,
      attributes: this.emotion.attributes
    },
    reason: this.reason,
    people: this.people,
    activities: this.activities,
    privacy: this.privacy,
    location: this.location ? {
      displayName: this.location.name,
      coordinates: this.location.coordinates,
      isShared: this.location.isShared
    } : null,
    timestamp: this.timestamp,
    isAnonymous: this.isAnonymous
  };
});

// Indexes for efficient querying
moodCheckInSchema.index({ userId: 1, timestamp: -1 });
moodCheckInSchema.index({ privacy: 1 });
moodCheckInSchema.index({ 'people.userId': 1 });
moodCheckInSchema.index({ 'location.coordinates': '2dsphere' });

const MoodCheckIn = mongoose.model('MoodCheckIn', moodCheckInSchema);

export default MoodCheckIn;