const express = require('express');
const mongoose = require('mongoose');
const bodyParser = require('body-parser');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const cors = require('cors');
require('dotenv').config();

const app = express();
app.use(bodyParser.json());
app.use(cors());

mongoose.connect('mongodb://localhost:27017/scorer');

// User model
const userSchema = new mongoose.Schema({
  firstName: { type: String, required: true },
  lastName: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  contactNumber: { type: String },
  profileId: { type: String, required: true, unique: true },
  god_admin: { type: Boolean, default: false },
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

// League model
const leagueSchema = new mongoose.Schema({
  leagueId: { type: String, required: true, unique: true },
  leagueName: { type: String, required: true },
  sport: { type: String, required: true, enum: ['throwball', 'cricket'] },
  teams: [
    {
      teamId: { type: String },
      teamName: { type: String }
    }
  ],
  status: { type: String, enum: ['scheduled', 'completed', 'ongoing'], default: 'scheduled' }
});
const League = mongoose.model('League', leagueSchema);

const teamSchema = new mongoose.Schema({
  teamId: {
    type: String,
    required: true,
    unique: true,
    default: () => new mongoose.Types.ObjectId().toString(),
  },
  teamName: {
    type: String,
    required: true,
  },
  players: {
    type: [String], // List of player IDs or names
    default: [],
  },
});
// Ensure unique teamName per league (case-insensitive)
teamSchema.index({ teamName: 1}, { unique: true, collation: { locale: 'en', strength: 2 } });
const Team = mongoose.model('Team', teamSchema);

// JWT secret
const JWT_SECRET = process.env.JWT_SECRET || 'your_jwt_secret';

// Generic helper to generate unique IDs
function generateUniqueId(type) {
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
  if (!hasLetter || !hasNumber) return generateUniqueId(type);
  return id;
}

// Middleware to authenticate user from JWT token
async function getUserFromToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  if (!authHeader) return res.status(401).json({ error: 'No authorization header.' });
  const token = authHeader.replace('Bearer ', '');
  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    const user = await User.findOne({ email: decoded.email });
    if (!user) return res.status(401).json({ error: 'Invalid token.' });
    req.user = user;
    next();
  } catch (err) {
    return res.status(401).json({ error: 'Invalid or expired token.' });
  }
}

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
  const profileId = generateUniqueId('profile');
  const hashedPassword = bcrypt.hashSync(password, 10);
  const user = new User({
    firstName,
    lastName,
    email,
    password: hashedPassword,
    contactNumber,
    profileId,
    god_admin: false,
    roles: [{ leagueId: null, teamId: null, role: 'player' }],
  });
  await user.save();
  res.status(201).json({ message: 'User registered successfully.', profileId });
});

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
    const token = jwt.sign({ email: user.email }, JWT_SECRET, { expiresIn: '7d' });
    return res.status(200).json({
      firstName: user.firstName,
      lastName: user.lastName,
      email: user.email,
      contactNumber: user.contactNumber,
      profileId: user.profileId,
      roles: user.roles,
      god_admin: user.god_admin,
      token
    });
  } catch (err) {
    return res.status(500).json({ error: 'Server error.' });
  }
});

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
    const tempPassword = Math.random().toString(36).slice(-8);
    user.password = bcrypt.hashSync(tempPassword, 10);
    await user.save();
    return res.status(200).json({ message: 'Password reset. Check your email for the new password.', tempPassword });
  } catch (err) {
    return res.status(500).json({ error: 'Server error.' });
  }
});

app.post('/update-user-role', getUserFromToken, async (req, res) => {
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

app.post('/add-league', async (req, res) => {
  const { leagueName, sport, teams, status } = req.body;
  if (!leagueName || !sport) {
    return res.status(400).json({ error: 'leagueName and sport are required.' });
  }
  try {
    let leagueId;
    let existingLeague;
    do {
      leagueId = generateUniqueId('league');
      existingLeague = await League.findOne({ leagueId });
    } while (existingLeague);
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

app.get('/leagues', async (req, res) => {
  try {
    const leagues = await League.find({});
    res.status(200).json(leagues);
  } catch (err) {
    res.status(500).json({ error: 'Server error.' });
  }
});

// Endpoint to fetch all teams
app.get('/teams', async (req, res) => {
  try {
    const teams = await Team.find().collation({ locale: 'en', strength: 2 });
    res.json(teams);
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch teams' });
  }
});

// Endpoint to create a new team
app.post('/add-teams', async (req, res) => {
  const { teamName, players } = req.body;
  if (!teamName) {
    return res.status(400).json({ error: 'Team name is required.' });
  }
  try {
    // Check for duplicate teamName (case-insensitive)
    const existingTeam = await Team.findOne({ teamName: teamName }).collation({ locale: 'en', strength: 2 });
    if (existingTeam) {
      return res.status(409).json({ error: 'A team with this name already exists.' });
    }
    const teamId = generateUniqueId('team');
    const team = new Team({
      teamId,
      teamName,
      players: Array.isArray(players) ? players : [],
    });
    await team.save();
    return res.status(201).json({ message: 'Team created successfully.', team });
  } catch (err) {
    return res.status(500).json({ error: 'Failed to create team.' });
  }
});

app.post('/validate-password', getUserFromToken, async (req, res) => {
  const { oldPassword } = req.body;
  if (!oldPassword || typeof oldPassword !== 'string') return res.status(400).json({ error: 'Old password required.' });
  const valid = await bcrypt.compare(oldPassword, req.user.password);
  return res.status(200).json({ valid });
});

app.post('/change-password', getUserFromToken, async (req, res) => {
  const { newPassword } = req.body;
  req.user.password = bcrypt.hashSync(newPassword, 10);
  await req.user.save();
  return res.status(200).json({ message: 'Password updated.' });
});

app.post('/delete-account', getUserFromToken, async (req, res) => {
  await User.deleteOne({ email: req.user.email });
  return res.status(200).json({ message: 'Account deleted.' });
});

// Endpoint to fetch team members by teamId
app.get('/team-members/:teamId', async (req, res) => {
  const { teamId } = req.params;
  try {
    const team = await Team.findOne({ teamId });
    if (!team) {
      return res.status(404).json({ error: 'Team not found.' });
    }
    res.json({
      teamName: team.teamName,
      players: team.players
    });
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch team members.' });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
