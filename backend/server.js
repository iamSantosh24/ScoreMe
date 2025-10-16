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

// Endpoint to fetch all teams
app.get('/teams', async (req, res) => {
  try {
    const teams = await Team.find().collation({ locale: 'en', strength: 2 });
    res.json(teams);
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch teams' });
  }
});

// Alias for frontend expecting /api/teams
app.get('/api/teams', async (req, res) => {
  try {
    const teams = await Team.find().collation({ locale: 'en', strength: 2 });
    res.json(teams);
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch teams' });
  }
});

// Existing leagues endpoint
app.get('/leagues', async (req, res) => {
  try {
    const leagues = await League.find({});
    res.status(200).json(leagues);
  } catch (err) {
    res.status(500).json({ error: 'Server error.' });
  }
});

// Alias for frontend expecting /api/leagues
app.get('/api/leagues', async (req, res) => {
  try {
    const leagues = await League.find({});
    res.status(200).json(leagues);
  } catch (err) {
    res.status(500).json({ error: 'Server error.' });
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

// Endpoint to fetch full player details for all team members
app.get('/team-members-details/:teamId', async (req, res) => {
  const { teamId } = req.params;
  try {
    const team = await Team.findOne({ teamId });
    if (!team) {
      return res.status(404).json({ error: 'Team not found.' });
    }
    // Fetch all users whose profileId is in team.players
    const users = await User.find({ profileId: { $in: team.players } }, {
      firstName: 1,
      lastName: 1,
      email: 1,
      profileId: 1
    });
    // Sort users in the same order as team.players
    const sortedUsers = team.players.map(pid => users.find(u => u.profileId === pid)).filter(Boolean);
    res.json({
      teamName: team.teamName,
      players: sortedUsers
    });
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch team member details.' });
  }
});

// --- Added API endpoints for user search and role assignment ---

// GET /api/users?search=...  -- returns simple user list for UI search
app.get('/api/users', async (req, res) => {
  try {
    const { search } = req.query;
    let filter = {};
    if (search && typeof search === 'string' && search.trim() !== '') {
      const q = search.trim();
      const re = new RegExp(q, 'i');
      filter = {
        $or: [
          { firstName: re },
          { lastName: re },
          { email: re },
          { profileId: re }
        ]
      };
    }
    // Limit results to avoid huge payloads
    const users = await User.find(filter).limit(50).select('firstName lastName email profileId');
    const mapped = users.map(u => ({
      _id: u._id,
      username: u.email || u.profileId,
      displayName: `${u.firstName || ''}${u.lastName ? ' ' + u.lastName : ''}`.trim(),
      email: u.email,
      profileId: u.profileId
    }));
    res.json(mapped);
  } catch (err) {
    console.error('GET /api/users error', err);
    res.status(500).json({ error: 'Failed to fetch users' });
  }
});

// GET /api/users/:id  -- return full user document (includes roles and god_admin)
app.get('/api/users/:id', async (req, res) => {
  try {
    const { id } = req.params;
    // Try to find by Mongo ObjectId first; if not found, try by profileId/email
    let user = null;
    try {
      user = await User.findById(id);
    } catch (e) {
      // ignore invalid ObjectId parse errors and try other lookups
    }

    if (!user) {
      user = await User.findOne({ $or: [{ profileId: id }, { email: id }] });
    }

    if (!user) return res.status(404).json({ error: 'User not found.' });
    // Return the full document (be mindful of sensitive fields in production)
    res.json(user);
  } catch (err) {
    console.error('GET /api/users/:id error', err);
    res.status(500).json({ error: 'Failed to fetch user' });
  }
});

// POST /api/assign-role
// Body: { userId, role: 'admin'|'super_admin', teamId?, leagueId? }
// Requires authentication. Performs basic authorization checks.
app.post('/api/assign-role', getUserFromToken, async (req, res) => {
  try {
    let { userId, role, teamId, leagueId } = req.body;
    if (!userId || !role) return res.status(400).json({ error: 'userId and role required' });

    const requester = req.user;
    const isGod = requester.god_admin === true;
    let allowed = isGod;

    // If assigning a team admin and leagueId not provided, try to resolve leagueId from teamId
    if (role === 'admin' && !leagueId && teamId) {
      try {
        const leagueWithTeam = await League.findOne({ 'teams.teamId': teamId });
        if (leagueWithTeam) {
          leagueId = leagueWithTeam.leagueId;
        }
      } catch (e) {
        // ignore resolution error; authorization will fail if not resolvable
      }
    }

    if (!allowed) {
      if (role === 'admin') {
        // For assigning a team admin we allow requester if they are super_admin for the same league
        if (leagueId) {
          allowed = Array.isArray(requester.roles) && requester.roles.some(r => r.role === 'super_admin' && r.leagueId === leagueId);
        } else {
          // no leagueId provided and could not resolve -> do not allow
          allowed = false;
        }
      } else if (role === 'super_admin') {
        // assigning super_admin is sensitive: only god_admin allowed
        allowed = false;
      }
    }

    if (!allowed) return res.status(403).json({ error: 'Not authorized to assign this role' });

    const user = await User.findById(userId);
    if (!user) return res.status(404).json({ error: 'User not found' });

    let updated = false;

    // Treat god_admin as a boolean on the user, not as a role in the roles array
    if (role === 'god_admin') {
      // Only a god_admin may assign another god_admin (allowed already enforces this)
      user.god_admin = true;
      updated = true;
    } else if (leagueId || teamId) {
      for (let r of user.roles) {
        if ((leagueId && r.leagueId === leagueId) || (teamId && r.teamId === teamId)) {
          r.role = role;
          updated = true;
          break;
        }
      }
      if (!updated) {
        user.roles.push({ leagueId: leagueId || null, teamId: teamId || null, role });
        updated = true;
      }
    } else {
      if (user.roles.length > 0) {
        user.roles[0].role = role;
      } else {
        user.roles.push({ leagueId: null, teamId: null, role });
      }
      updated = true;
    }

    await user.save();
    return res.status(200).json({ message: 'Role assigned', user });
  } catch (err) {
    console.error('POST /api/assign-role error', err);
    return res.status(500).json({ error: 'Server error' });
  }
});

// POST /api/remove-role
// Body: { userId, role: 'admin'|'super_admin'|'god_admin'|..., teamId?, leagueId? }
// Requires authentication. Performs basic authorization checks similar to assign-role.
app.post('/api/remove-role', getUserFromToken, async (req, res) => {
  try {
    let { userId, role, teamId, leagueId } = req.body;
    if (!userId || !role) return res.status(400).json({ error: 'userId and role required' });

    const requester = req.user;
    const isGod = requester.god_admin === true;
    let allowed = isGod;

    // If removing a team-scoped admin and leagueId not provided, try to resolve leagueId from teamId
    if (role === 'admin' && !leagueId && teamId) {
      try {
        const leagueWithTeam = await League.findOne({ 'teams.teamId': teamId });
        if (leagueWithTeam) {
          leagueId = leagueWithTeam.leagueId;
        }
      } catch (e) {
        // ignore resolution error; authorization will fail if not resolvable
      }
    }

    if (!allowed) {
      if (role === 'admin') {
        // allow super_admins of the same league to remove team admins
        if (leagueId) {
          allowed = Array.isArray(requester.roles) && requester.roles.some(r => r.role === 'super_admin' && r.leagueId === leagueId);
        } else {
          allowed = false;
        }
      } else if (role === 'super_admin') {
        // removing super_admin is sensitive: only god_admin allowed
        allowed = false;
      } else {
        // For other roles (including god_admin), require god_admin
        allowed = false;
      }
    }

    if (!allowed) return res.status(403).json({ error: 'Not authorized to remove this role' });

    const user = await User.findById(userId);
    if (!user) return res.status(404).json({ error: 'User not found' });

    // If removing god_admin, unset the boolean and save
    if (role === 'god_admin') {
      if (!user.god_admin) {
        return res.status(404).json({ error: 'User is not a god_admin' });
      }
      user.god_admin = false;
      await user.save();
      return res.status(200).json({ message: 'Role removed', user });
    }

    // Find the exact role entry to remove. Roles are stored as objects with optional leagueId/teamId and role.
    let removed = false;

    if (leagueId || teamId) {
      // Remove the entry that matches both role and the provided scope
      for (let i = user.roles.length - 1; i >= 0; i--) {
        const r = user.roles[i];
        const matchLeague = leagueId ? (r.leagueId === leagueId) : (r.leagueId == null);
        const matchTeam = teamId ? (r.teamId === teamId) : (r.teamId == null);
        if (r.role === role && matchLeague && matchTeam) {
          user.roles.splice(i, 1);
          removed = true;
          break;
        }
      }
    } else {
      // No scope provided: try to remove a global/unspecified scoped role that matches the name
      for (let i = user.roles.length - 1; i >= 0; i--) {
        const r = user.roles[i];
        const noScope = (r.leagueId == null || r.leagueId === '') && (r.teamId == null || r.teamId === '');
        if (r.role === role && noScope) {
          user.roles.splice(i, 1);
          removed = true;
          break;
        }
      }
    }

    if (!removed) {
      return res.status(404).json({ error: 'Role not found on user' });
    }

    await user.save();
    return res.status(200).json({ message: 'Role removed', user });
  } catch (err) {
    console.error('POST /api/remove-role error', err);
    return res.status(500).json({ error: 'Server error' });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
