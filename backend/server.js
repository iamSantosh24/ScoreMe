const express = require('express');
const mongoose = require('mongoose');
const bodyParser = require('body-parser');
const bcrypt = require('bcryptjs');

const app = express();
app.use(bodyParser.json());

// Connect to MongoDB
mongoose.connect('mongodb://localhost:27017/scorer', {
  useNewUrlParser: true,
  useUnifiedTopology: true,
});

// User Schema
const userSchema = new mongoose.Schema({
  firstName: { type: String, required: true },
  lastName: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  contactNumber: { type: String },
  profileId: { type: String, required: true, unique: true },
  god_admin: { type: Boolean, default: false }, // app-level permission
  roles: [
    {
      leagueId: { type: String },
      teamId: { type: String },
      role: {
        type: String,
        enum: ['super_admin', 'admin', 'player'],
        default: 'player',
      },
    },
  ],
});

const User = mongoose.model('User', userSchema);

// Helper to generate profileId
function generateProfileId() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  let id = '';
  let hasLetter = false;
  let hasNumber = false;
  while (id.length < 7) {
    const c = chars[Math.floor(Math.random() * chars.length)];
    id += c;
    if (/[A-Z]/.test(c)) hasLetter = true;
    if (/[0-9]/.test(c)) hasNumber = true;
  }
  // Ensure at least one letter and one number
  if (!hasLetter || !hasNumber) return generateProfileId();
  return id;
}

// Registration endpoint
app.post('/register', async (req, res) => {
  const { firstName, lastName, email, password, confirmPassword, contactNumber } = req.body;
  if (!firstName || !lastName || !email || !password || !confirmPassword) {
    return res.status(400).json({ error: 'Missing required fields.' });
  }
  if (password !== confirmPassword) {
    return res.status(400).json({ error: 'Passwords do not match.' });
  }
  const existingUser = await User.findOne({ email });
  if (existingUser) {
    return res.status(409).json({ error: 'Email already registered.' });
  }
  const profileId = generateProfileId();
  const hashedPassword = bcrypt.hashSync(password, 10);
  const user = new User({
    firstName,
    lastName,
    email,
    password: hashedPassword,
    contactNumber,
    profileId,
    god_admin: false, // default
    roles: [{ leagueId: null, teamId: null, role: 'player' }], // default role
  });
  await user.save();
  res.status(201).json({ message: 'User registered successfully.', profileId });
});

// Start server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
