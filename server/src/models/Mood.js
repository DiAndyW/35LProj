import mongoose from 'mongoose';

const { Schema, Types } = mongoose;

const moodSchema = new Schema({

  //Reference to userID
  userId: {
    type: Schema.Types.ObjectId,
    ref: 'User', 
    required: true
  },

  //Mood Information
  mood: {
    label: {
      type: String,
      required: true
    },
    coordinates: {
      type: [Number],
      validate: {
        validator: function(v) {
          return v.length === 4;
        },
      }
    },
    note: String,
    time: {
      type: Date,
      default: Date.now
    }
  },

  //Location Information
  location: {
    label: String,
    coordinates: {
      type: [Number],
      validate: {
        validator: function(v) {
          return v.length === 2;
        },
      }
    },
    isPrecise: {
      type: Boolean,
      default: false
    }
  },

  //Is this upload anonymous?
  isAnonymous: {
    type: Boolean,
    default: true
  }
});

export default mongoose.model('Mood', moodSchema);