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

// League Schema
const leagueSchema = new mongoose.Schema({
  leagueId: { type: String, required: true, unique: true },
  leagueName: { type: String, required: true },
  sport: { type: String, required: true, enum: ['throwball', 'cricket'] },
  teams: [
    {
      teamId: { type: String },
      teamName: { type: String }
      // Add more team fields as needed
    }
  ],
  status: { type: String, enum: ['scheduled', 'completed', 'ongoing'], default: 'scheduled' }
});

const League = mongoose.model('League', leagueSchema);

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

// Login endpoint
app.post('/login', async (req, res) => {
  const { email, password } = req.body;
  if (!email || !password) {
    return res.status(400).json({ error: 'Email and password required.' });
  }
  try {
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(401).json({ error: 'Invalid email or password.' });
    }
    const validPassword = await bcrypt.compare(password, user.password);
    if (!validPassword) {
      return res.status(401).json({ error: 'Invalid email or password.' });
    }
    // Success: return user details
    return res.status(200).json({
      firstName: user.firstName,
      lastName: user.lastName,
      email: user.email,
      contactNumber: user.contactNumber,
      profileId: user.profileId,
      roles: user.roles,
      god_admin: user.god_admin
    });
  } catch (err) {
    return res.status(500).json({ error: 'Server error.' });
  }
});

// Forgot Password endpoint
app.post('/forgot-password', async (req, res) => {
  const { email } = req.body;
  if (!email) {
    return res.status(400).json({ error: 'Email is required.' });
  }
  try {
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(404).json({ error: 'No user found with this email.' });
    }
    // Generate a temporary password (or token) and update user's password
    const tempPassword = Math.random().toString(36).slice(-8);
    user.password = bcrypt.hashSync(tempPassword, 10);
    await user.save();
    // TODO: Send tempPassword to user's email (implement email sending logic)
    // For now, just return the temp password in response (for testing)
    return res.status(200).json({ message: 'Password reset. Check your email for the new password.', tempPassword });
  } catch (err) {
    return res.status(500).json({ error: 'Server error.' });
  }
});

// Update user god_admin and/or role endpoint
app.post('/update-user-role', async (req, res) => {
  const { email, god_admin, role, leagueId, teamId } = req.body;
  if (!email) {
    return res.status(400).json({ error: 'Email is required.' });
  }
  try {
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(404).json({ error: 'User not found.' });
    }
    let updatedFields = {};
    if (typeof god_admin === 'boolean') {
      user.god_admin = god_admin;
      updatedFields.god_admin = god_admin;
    }
    if (role) {
      // Update or add role for league/team context
      let found = false;
      if (leagueId || teamId) {
        for (let r of user.roles) {
          if ((leagueId && r.leagueId === leagueId) || (teamId && r.teamId === teamId)) {
            r.role = role;
            found = true;
            break;
          }
        }
        if (!found) {
          user.roles.push({ leagueId: leagueId || null, teamId: teamId || null, role });
        }
      } else {
        // If no leagueId/teamId, update first role or add new
        if (user.roles.length > 0) {
          user.roles[0].role = role;
        } else {
          user.roles.push({ leagueId: null, teamId: null, role });
        }
      }
      updatedFields.role = role;
      updatedFields.leagueId = leagueId;
      updatedFields.teamId = teamId;
    }
    await user.save();
    return res.status(200).json({ message: 'User updated.', updatedFields, user });
  } catch (err) {
    return res.status(500).json({ error: 'Server error.' });
  }
});

// Add League endpoint
app.post('/add-league', async (req, res) => {
  const { leagueId, leagueName, sport, teams, status } = req.body;
  if (!leagueId || !leagueName || !sport) {
    return res.status(400).json({ error: 'leagueId, leagueName, and sport are required.' });
  }
  try {
    const existingLeague = await League.findOne({ leagueId });
    if (existingLeague) {
      return res.status(409).json({ error: 'League with this leagueId already exists.' });
    }
    const league = new League({
      leagueId,
      leagueName,
      sport,
      teams: teams || [],
      status: status || 'scheduled'
    });
    await league.save();
    return res.status(201).json({ message: 'League created successfully.', league });
  } catch (err) {
    return res.status(500).json({ error: 'Server error.' });
  }
});

// Fetch all leagues
app.get('/leagues', async (req, res) => {
  try {
    const leagues = await League.find({});
    res.status(200).json(leagues);
  } catch (err) {
    res.status(500).json({ error: 'Server error.' });
  }
});

// Start server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
