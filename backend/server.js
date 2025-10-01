const express = require('express');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const bodyParser = require('body-parser');
const cors = require('cors');
const mongoose = require('mongoose');

const app = express();
app.use(bodyParser.json());
app.use(cors());

const SECRET = 'your_jwt_secret';

// Connect to MongoDB
mongoose.connect('mongodb://localhost:27017/scorer', { useNewUrlParser: true, useUnifiedTopology: true });
const db = mongoose.connection;
db.on('error', console.error.bind(console, 'MongoDB connection error:'));
db.once('open', () => console.log('Connected to MongoDB'));

// User schema/model
const userSchema = new mongoose.Schema({
  username: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  role: { type: String, required: true }
});
const User = mongoose.model('User', userSchema);

// Tournament schema/model
const tournamentSchema = new mongoose.Schema({
  name: { type: String, required: true, unique: true },
  games: [{ type: String }], // Added games array
  members: [{ type: String }], // Added members array
});
const Tournament = mongoose.model('Tournament', tournamentSchema);

// Team schema/model
const teamSchema = new mongoose.Schema({
  name: { type: String, required: true },
  tournament: { type: mongoose.Schema.Types.ObjectId, ref: 'Tournament', required: true },
  members: [{ type: String }], // Added members array
});
const Team = mongoose.model('Team', teamSchema);

// GodAdmin group schema/model
const godAdminSchema = new mongoose.Schema({
  username: { type: String, required: true, unique: true }
});
const GodAdmin = mongoose.model('GodAdmin', godAdminSchema);

// SuperAdmin assignment per league
const superAdminSchema = new mongoose.Schema({
  leagueId: { type: mongoose.Schema.Types.ObjectId, ref: 'Tournament', required: true },
  username: { type: String, required: true }
});
const SuperAdmin = mongoose.model('SuperAdmin', superAdminSchema);

// Admin assignment per team
const teamAdminSchema = new mongoose.Schema({
  teamId: { type: mongoose.Schema.Types.ObjectId, ref: 'Team', required: true },
  username: { type: String, required: true }
});
const TeamAdmin = mongoose.model('TeamAdmin', teamAdminSchema);

// Player requests to join team
const teamPlayerRequestSchema = new mongoose.Schema({
  teamId: { type: mongoose.Schema.Types.ObjectId, ref: 'Team', required: true },
  username: { type: String, required: true },
  status: { type: String, enum: ['pending', 'approved', 'rejected'], default: 'pending' }
});
const TeamPlayerRequest = mongoose.model('TeamPlayerRequest', teamPlayerRequestSchema);

// ScheduledGame schema/model
const scheduledGameSchema = new mongoose.Schema({
  gameName: { type: String, required: true },
  leagueId: { type: String, required: true },
  leagueName: { type: String }, // Added leagueName field
  teamA: { type: String, required: true },
  teamB: { type: String, required: true },
  date: { type: Date, required: true }
});
// This model will use the 'scheduledgames' collection in MongoDB
const ScheduledGame = mongoose.model('ScheduledGame', scheduledGameSchema);

// Helper to check god_admin status
async function isGodAdmin(username) {
  const admin = await GodAdmin.findOne({ username });
  return !!admin;
}

// Middleware to check god_admin group
async function requireGodAdmin(req, res, next) {
  const auth = req.headers.authorization;
  if (!auth) return res.status(401).json({ error: 'No token' });
  try {
    const decoded = jwt.verify(auth.replace('Bearer ', ''), SECRET);
    if (!(await isGodAdmin(decoded.username))) {
      return res.status(403).json({ error: 'Forbidden: god_admins only' });
    }
    req.user = decoded;
    next();
  } catch (e) {
    res.status(401).json({ error: 'Invalid token' });
  }
}

// Registration endpoint (no role selection, always 'player')
app.post('/register', async (req, res) => {
  const { username, password } = req.body;
  if (!username || !password) {
    return res.status(400).json({ error: 'Missing fields' });
  }
  // Email format validation
  const emailRegex = /^[^@\s]+@[^@\s]+\.[^@\s]+$/;
  if (!emailRegex.test(username)) {
    return res.status(400).json({ error: 'Username must be a valid email address' });
  }
  try {
    const existingUser = await User.findOne({ username });
    if (existingUser) {
      return res.status(409).json({ error: 'An account with this email already exists' });
    }
    const hashedPassword = bcrypt.hashSync(password, 8);
    const newUser = new User({ username, password: hashedPassword, role: 'player' });
    await newUser.save();
    res.json({ message: 'User registered successfully' });
  } catch (err) {
    res.status(500).json({ error: 'Registration failed' });
  }
});

// Login endpoint (no role required)
app.post('/login', async (req, res) => {
  const { username, password } = req.body;
  try {
    const user = await User.findOne({ username });
    if (!user) return res.status(401).json({ error: 'Invalid credentials' });
    const passwordMatch = bcrypt.compareSync(password, user.password);
    if (!passwordMatch) return res.status(401).json({ error: 'Invalid credentials' });
    const token = jwt.sign({ username: user.username, role: user.role }, SECRET, { expiresIn: '1h' });
    res.json({ token, role: user.role });
  } catch (err) {
    res.status(500).json({ error: 'Login failed. Please try again' });
  }
});

// Example protected endpoint
app.get('/profile', (req, res) => {
  const auth = req.headers.authorization;
  if (!auth) return res.status(401).json({ error: 'No token' });
  try {
    const decoded = jwt.verify(auth.replace('Bearer ', ''), SECRET);
    res.json({ username: decoded.username, role: decoded.role });
  } catch (e) {
    res.status(401).json({ error: 'Invalid token' });
  }
});

// Tournament endpoints
app.post('/tournaments', async (req, res) => {
  const { name } = req.body;
  if (!name) return res.status(400).json({ error: 'Missing tournament name' });
  try {
    const tournament = new Tournament({ name });
    await tournament.save();
    res.json({ message: 'Tournament created', tournament });
  } catch (err) {
    res.status(500).json({ error: 'Failed to create tournament' });
  }
});

app.get('/tournaments', async (req, res) => {
  try {
    const tournaments = await Tournament.find();
    res.json({ tournaments });
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch tournaments' });
  }
});

// Team endpoints
app.post('/teams', async (req, res) => {
  const { name, tournamentId, members } = req.body;
  if (!name || !tournamentId) return res.status(400).json({ error: 'Missing team name or tournamentId' });
  try {
    const team = new Team({ name, tournament: tournamentId, members: Array.isArray(members) ? members : [] });
    await team.save();
    res.json({ message: 'Team created', team });
  } catch (err) {
    res.status(500).json({ error: 'Failed to create team' });
  }
});

// Endpoint to list god admins
app.get('/god-admins', requireGodAdmin, async (req, res) => {
  try {
    const admins = await GodAdmin.find({}, 'username');
    res.json({ admins });
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch god admins' });
  }
});

// Endpoint to add a god admin (only by existing god_admin)
app.post('/add-god-admin', requireGodAdmin, async (req, res) => {
  const { username } = req.body;
  if (!username) return res.status(400).json({ error: 'Missing username' });
  try {
    const user = await User.findOne({ username });
    if (!user) return res.status(404).json({ error: 'User not found' });
    const existing = await GodAdmin.findOne({ username });
    if (existing) return res.status(409).json({ error: 'User is already a god_admin' });
    await new GodAdmin({ username }).save();
    res.json({ message: 'User added to god_admin group', username });
  } catch (err) {
    res.status(500).json({ error: 'Failed to add god admin' });
  }
});

// Endpoint to remove a god admin (only by existing god_admin)
app.post('/remove-god-admin', requireGodAdmin, async (req, res) => {
  const { username } = req.body;
  if (!username) return res.status(400).json({ error: 'Missing username' });
  try {
    await GodAdmin.deleteOne({ username });
    res.json({ message: 'User removed from god_admin group', username });
  } catch (err) {
    res.status(500).json({ error: 'Failed to remove god admin' });
  }
});

// Endpoint to list all users (for god_admin panel)
app.get('/users', async (req, res) => {
  try {
    const users = await User.find({}, 'username role');
    res.json({ users });
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch users' });
  }
});

// Endpoint: god admin assigns super admin to league
app.post('/assign-super-admin', requireGodAdmin, async (req, res) => {
  const { leagueId, username } = req.body;
  if (!leagueId || !username) return res.status(400).json({ error: 'Missing fields' });
  try {
    const user = await User.findOne({ username });
    if (!user) return res.status(404).json({ error: 'User not found' });
    await SuperAdmin.findOneAndUpdate(
      { leagueId },
      { leagueId, username },
      { upsert: true, new: true }
    );
    res.json({ message: 'Super admin assigned to league', leagueId, username });
  } catch (err) {
    res.status(500).json({ error: 'Failed to assign super admin' });
  }
});

// Endpoint: super admin assigns admin to team
app.post('/assign-admin', async (req, res) => {
  const { teamId, username, leagueId } = req.body;
  if (!teamId || !username || !leagueId) return res.status(400).json({ error: 'Missing fields' });
  // Check if requester is super admin for league
  const auth = req.headers.authorization;
  if (!auth) return res.status(401).json({ error: 'No token' });
  try {
    const decoded = jwt.verify(auth.replace('Bearer ', ''), SECRET);
    const superAdmin = await SuperAdmin.findOne({ leagueId, username: decoded.username });
    if (!superAdmin) return res.status(403).json({ error: 'Forbidden: super admins only' });
    await TeamAdmin.findOneAndUpdate(
      { teamId },
      { teamId, username },
      { upsert: true, new: true }
    );
    res.json({ message: 'Admin assigned to team', teamId, username });
  } catch (err) {
    res.status(500).json({ error: 'Failed to assign admin' });
  }
});

// Endpoint: player requests to join team
app.post('/request-join-team', async (req, res) => {
  const { teamId } = req.body;
  const auth = req.headers.authorization;
  if (!auth) return res.status(401).json({ error: 'No token' });
  try {
    const decoded = jwt.verify(auth.replace('Bearer ', ''), SECRET);
    await new TeamPlayerRequest({ teamId, username: decoded.username }).save();
    res.json({ message: 'Request submitted' });
  } catch (err) {
    res.status(500).json({ error: 'Failed to submit request' });
  }
});

// Endpoint: admin approves/rejects player request
app.post('/review-player-request', async (req, res) => {
  const { requestId, status, teamId } = req.body;
  const auth = req.headers.authorization;
  if (!auth) return res.status(401).json({ error: 'No token' });
  try {
    const decoded = jwt.verify(auth.replace('Bearer ', ''), SECRET);
    const admin = await TeamAdmin.findOne({ teamId, username: decoded.username });
    if (!admin) return res.status(403).json({ error: 'Forbidden: team admins only' });
    const request = await TeamPlayerRequest.findById(requestId);
    if (!request) return res.status(404).json({ error: 'Request not found' });
    request.status = status;
    await request.save();
    res.json({ message: `Player request ${status}` });
  } catch (err) {
    res.status(500).json({ error: 'Failed to review request' });
  }
});

// Change username endpoint
app.post('/change-username', async (req, res) => {
  const auth = req.headers.authorization;
  if (!auth) return res.status(401).json({ error: 'No token' });
  try {
    const decoded = jwt.verify(auth.replace('Bearer ', ''), SECRET);
    const { newUsername } = req.body;
    const emailRegex = /^[^@\s]+@[^@\s]+\.[^@\s]+$/;
    if (!emailRegex.test(newUsername)) {
      return res.status(400).json({ error: 'Username must be a valid email address' });
    }
    const existingUser = await User.findOne({ username: newUsername });
    if (existingUser) {
      return res.status(409).json({ error: 'An account with this email already exists' });
    }
    await User.updateOne({ username: decoded.username }, { username: newUsername });
    res.json({ message: 'Username updated' });
  } catch (err) {
    res.status(500).json({ error: 'Failed to update username' });
  }
});

// Change password endpoint
app.post('/change-password', async (req, res) => {
  const auth = req.headers.authorization;
  if (!auth) return res.status(401).json({ error: 'No token' });
  try {
    const decoded = jwt.verify(auth.replace('Bearer ', ''), SECRET);
    const { newPassword } = req.body;
    if (!newPassword || newPassword.length < 6) {
      return res.status(400).json({ error: 'Password must be at least 6 characters' });
    }
    const hashedPassword = bcrypt.hashSync(newPassword, 8);
    await User.updateOne({ username: decoded.username }, { password: hashedPassword });
    res.json({ message: 'Password updated' });
  } catch (err) {
    res.status(500).json({ error: 'Failed to update password' });
  }
});

// Delete account endpoint
app.post('/delete-account', async (req, res) => {
  const auth = req.headers.authorization;
  if (!auth) return res.status(401).json({ error: 'No token' });
  try {
    const decoded = jwt.verify(auth.replace('Bearer ', ''), SECRET);
    await User.deleteOne({ username: decoded.username });
    res.json({ message: 'Account deleted' });
  } catch (err) {
    res.status(500).json({ error: 'Failed to delete account' });
  }
});

// Search endpoint
app.get('/search', async (req, res) => {
  const { query } = req.query;
  if (!query || query.trim() === '') {
    return res.status(400).json({ error: 'Missing search query' });
  }
  try {
    const tournaments = await Tournament.find({ name: { $regex: query, $options: 'i' } });
    const players = await User.find({ username: { $regex: query, $options: 'i' } });
    res.json({ tournaments, players });
  } catch (err) {
    res.status(500).json({ error: 'Search failed' });
  }
});

// Get user's leagues and games
app.get('/user/leagues-and-games', async (req, res) => {
  const { username } = req.query;
  if (!username) return res.status(400).json({ error: 'Missing username' });
  try {
    const user = await User.findOne({ username });
    if (!user) return res.status(404).json({ error: 'User not found' });
    const leagues = await Tournament.find({ members: username });
    const leagueObjs = leagues.map(l => ({ _id: l._id, name: l.name }));
    const gamesSet = new Set();
    leagues.forEach(l => {
      if (Array.isArray(l.games)) {
        l.games.forEach(g => gamesSet.add(g));
      }
    });
    const games = Array.from(gamesSet);
    res.json({ leagues: leagueObjs, games });
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch leagues and games' });
  }
});

// Endpoint: get scheduled games for a user
app.get('/user/scheduled-games', async (req, res) => {
  const { username } = req.query;
  if (!username) return res.status(400).json({ error: 'Missing username' });
  try {
    // Find all teams for user
    const teams = await Team.find({ members: username });
    const teamNames = teams.map(t => t.name);
    // Find all games for user's teams
    const games = await ScheduledGame.find({
      $or: [
        { teamA: { $in: teamNames } },
        { teamB: { $in: teamNames } }
      ]
    });
    // Return date, teamA, teamB, gameName, leagueId and leagueName for each scheduled game
    const result = games.map(g => ({
      date: g.date,
      teamA: g.teamA,
      teamB: g.teamB,
      gameName: g.gameName,
      leagueId: g.leagueId,
      leagueName: g.leagueName
    }));
    res.json({ games: result });
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch scheduled games' });
  }
});

// Endpoint: get all scheduled games for a specific league
app.get('/league/scheduled-games', async (req, res) => {
  const { leagueId } = req.query;
  if (!leagueId) return res.status(400).json({ error: 'Missing leagueId' });
  try {
    const games = await ScheduledGame.find({ leagueId });
    // Fetch the league name from Tournament collection
    const league = await Tournament.findOne({ name: leagueId });
    const leagueName = league ? league.name : leagueId;
    const result = games.map(g => ({
      date: g.date,
      teamA: g.teamA,
      teamB: g.teamB,
      gameName: g.gameName,
      leagueName: leagueName
    }));
    res.json({ games: result });
  } catch (err) {
    console.error(`[ScheduledGame] Error fetching games for leagueId: ${leagueId}`, err);
    res.status(500).json({ error: 'Failed to fetch scheduled games for league' });
  }
});

// Endpoint: get tournament details by name
app.get('/tournament/details', async (req, res) => {
  const { id, name } = req.query;
  if (!id && !name) return res.status(400).json({ error: 'Missing tournament id or name' });
  try {
    let tournament;
    if (id) {
      tournament = await Tournament.findById(id);
    } else {
      tournament = await Tournament.findOne({ name });
    }
    if (!tournament) return res.status(404).json({ error: 'Tournament not found' });
    res.json({ tournament });
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch tournament details' });
  }
});

// Common endpoint to fetch scheduled games by league or user
app.get('/scheduled-games', async (req, res) => {
  const { leagueId, username } = req.query;
  try {
    let games = [];
    if (leagueId) {
      games = await ScheduledGame.find({ leagueId });
      // For each game, fetch the league name using leagueId (_id)
      const result = [];
      for (const g of games) {
        const league = await Tournament.findById(g.leagueId);
        result.push({
          date: g.date,
          teamA: g.teamA,
          teamB: g.teamB,
          gameName: g.gameName,
          leagueId: g.leagueId,
          leagueName: league ? league.name : g.leagueId
        });
      }
      return res.json({ games: result });
    } else if (username) {
      // Fetch games for all teams the user is part of
      const teams = await Team.find({ members: username });
      const teamNames = teams.map(t => t.name);
      games = await ScheduledGame.find({
        $or: [
          { teamA: { $in: teamNames } },
          { teamB: { $in: teamNames } }
        ]
      });
      // For each game, fetch the league name using leagueId (_id)
      const result = [];
      for (const g of games) {
        const league = await Tournament.findById(g.leagueId);
        result.push({
          date: g.date,
          teamA: g.teamA,
          teamB: g.teamB,
          gameName: g.gameName,
          leagueId: g.leagueId,
          leagueName: league ? league.name : g.leagueId
        });
      }
      return res.json({ games: result });
    } else {
      return res.status(400).json({ error: 'Missing leagueId or username' });
    }
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch scheduled games' });
  }
});

app.listen(3000, '0.0.0.0', () => console.log('Backend running on http://0.0.0.0:3000'));
