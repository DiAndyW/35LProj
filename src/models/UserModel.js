import mongoose from 'mongoose';
import bcrypt from 'bcrypt';

const userSchema = new mongoose.Schema({
  username: {
    type: String,
    required: [true, 'Username is required'],
    trim: true,
    minlength: [4, 'Username must be at least 4 characters'],
    maxlength: [16, 'Username cannot exceed 16 characters'],
    unique: true 
  },
  email: {
    type: String,
    required: [true, 'Email is required'],
    unique: true,
    lowercase: true,
    trim: true,
    validate: {
      validator: function(v) {
        const emailRegex = /^([\w-\.]+@([\w-]+\.)+[\w-]{2,4})?$/;
        return emailRegex.test(v);
      },
      message: props => `${props.value} is not a valid email address!`
    }
  },
  password: {
    type: String,
    required: [true, 'Password is required'],
    minlength: [8, 'Password must be at least 8 characters'],
    select: false 
  },
  profilePicture: {
    type: String,
    default: 'default-profile.png' // Store path to default image
  },
  preferences: {
    pushNotificationsEnabled: {
      type: Boolean,
      default: true
    },
    preferredNotificationTimeWindow: {
      start: {
        type: Number,
        min: 0,
        max: 23,
        default: 9
      },
      end: {
        type: Number,
        min: 0,
        max: 23,
        default: 21
      }
    },
    shareLocationForHeatmap: {
      type: Boolean,
      default: false
    },
    privacySettings: {
      showMoodToStrangers: {
        type: Boolean,
        default: false
      },
      anonymousMoodSharing: {
        type: Boolean,
        default: true
      }
    }
  },
  demographics: {
    graduatingClass: {
      type: Number
    },
    major: {
      type: String,
      trim: true
    },
    gender: {
      type: String,
      enum: ['Male', 'Female', 'Non-binary', 'Prefer not to say', 'Other'],
      default: 'Prefer not to say'
    },
    ethnicity: {
      type: String,
      trim: true
    },
    age: {
      type: Number,
      min: [18, 'Users must be at least 18 years old'],
      max: [100, 'Age must be a valid number']
    }
  },
  isActive: {
    type: Boolean,
    default: true
  },
  lastLogin: {
    type: Date,
    default: Date.now
  },
  refreshTokens: [{
    token: { type: String, required: true },
    createdAt: { type: Date, default: Date.now, expires: 604800 } // Auto-delete after 7 days
  }],
  passwordResetToken: {
    type: String
  },
  passwordResetExpires: {
    type: Date
  },
}, {
  timestamps: true
});

// Password hashing middleware
userSchema.pre('save', async function(next) {
  if (!this.isModified('password')) return next();
  try {
    this.password = await bcrypt.hash(this.password, 12);
    next();
  } catch (error) {
    next(error);
  }
});

export default mongoose.model('UserModel', userSchema);