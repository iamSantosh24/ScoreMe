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
  role: { type: String, required: true },
  firstName: { type: String, required: true },
  lastName: { type: String, required: true },
  teams: [{ type: String }], // Array of team IDs
  contactNumber: { type: String }
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
  _id: { type: String, required: true },
  gameName: { type: String },
  leagueId: { type: String },
  teamAId: { type: String },
  teamAName: { type: String },
  teamBId: { type: String },
  teamBName: { type: String },
  scheduledDate: { type: Date },
  location: { type: String },
  status: { type: String },
  sport: { type: String },
  tournamentId: { type: String }
}, { collection: 'scheduledgames' });
const ScheduledGame = mongoose.model('ScheduledGame', scheduledGameSchema);

// Leagues schema/model
const leagueSchema = new mongoose.Schema({
  _id: { type: String, required: true },
  name: { type: String, required: true },
  sport: { type: String },
  region: { type: String },
  createdAt: { type: Date },
  status: { type: String },
  teams: [{ type: String }]
});
const Leagues = mongoose.model('Leagues', leagueSchema, 'leagues');

// Team schema/model for teams collection
const teamsSchema = new mongoose.Schema({
  _id: { type: String, required: true },
  name: { type: String },
  leagueId: { type: mongoose.Schema.Types.Mixed }, // can be array or string
  members: [{ type: String }],
  sport: { type: String },
  createdAt: { type: Date }
});
const Teams = mongoose.model('Teams', teamsSchema, 'teams');

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
  const { username, password, confirmPassword, firstName, lastName, contactNumber, teams } = req.body;
  if (!username || !password || !confirmPassword || !firstName || !lastName) {
    return res.status(400).json({ error: 'Missing required fields' });
  }
  if (password !== confirmPassword) {
    return res.status(400).json({ error: 'Passwords do not match' });
  }
  // Email format validation
  const emailRegex = /^[^@\s]+@[^@\s]+\.[^@\s]+$/;
  if (!emailRegex.test(username)) {
    return res.status(400).json({ error: 'Username must be a valid email address' });
  }
  // Validate teams if provided
  let validTeams = [];
  if (Array.isArray(teams) && teams.length > 0) {
    const foundTeams = await Teams.find({ _id: { $in: teams } });
    validTeams = foundTeams.map(t => t._id);
    if (validTeams.length !== teams.length) {
      return res.status(400).json({ error: 'One or more selected teams are invalid' });
    }
  }
  try {
    const existingUser = await User.findOne({ username });
    if (existingUser) {
      return res.status(409).json({ error: 'An account with this email already exists' });
    }
    const hashedPassword = bcrypt.hashSync(password, 8);
    const newUser = new User({
      username,
      password: hashedPassword,
      role: 'player',
      firstName,
      lastName,
      contactNumber,
      teams: validTeams
    });
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

// Get user's leagues, games and teams
app.get('/user/leagues-games-teams', async (req, res) => {
  const { username, role } = req.query;
  if (!username) return res.status(400).json({ error: 'Missing username' });
  try {
    let teams = [];
    let leagues = [];
    let games = [];
    let leagueObjs = [];
    let teamObjs = [];
    let gameObjs = [];
    if (role === 'god_admin') {
      // God Admin: See all games, leagues, teams
      teams = await Team.find({});
      leagues = await Leagues.find({});
      games = await ScheduledGame.find({});
      leagueObjs = leagues.map(l => ({
        _id: l._id,
        name: l.name,
        sport: l.sport,
        region: l.region,
        status: l.status,
        teams: l.teams
      }));
      teamObjs = teams.map(t => ({
        _id: t._id,
        name: t.name,
        leagueId: t.tournament,
        sport: t.sport
      }));
      // Create a map of leagueId to leagueName
      const leagueIdToName = {};
      leagues.forEach(l => { leagueIdToName[l._id] = l.name; });
      gameObjs = games.map(g => ({
        _id: g._id,
        gameName: g.gameName || g.sport,
        leagueId: g.leagueId,
        leagueName: leagueIdToName[g.leagueId],
        teamAId: g.teamAId,
        teamAName: g.teamAName,
        teamBId: g.teamBId,
        teamBName: g.teamBName,
        scheduledDate: g.scheduledDate,
        location: g.location,
        status: g.status,
        sport: g.sport,
        tournamentId: g.tournamentId
      }));
    } else if (role === 'super_admin') {
      // Super Admin: See all games and teams in leagues where user is super admin
      const superAdminLeagues = await SuperAdmin.find({ username });
      const leagueIds = superAdminLeagues.map(l => l.leagueId);
      leagues = await Tournament.find({ _id: { $in: leagueIds } });
      teams = await Team.find({ tournament: { $in: leagueIds } });
      games = await ScheduledGame.find({ leagueId: { $in: leagueIds } });
      leagueObjs = leagues.map(l => ({
        _id: l._id,
        name: l.name,
        sport: l.sport,
        region: l.region,
        status: l.status,
        teams: l.teams
      }));
      teamObjs = teams.map(t => ({
        _id: t._id,
        name: t.name,
        leagueId: t.tournament,
        sport: t.sport
      }));
      const leagueIdToName = {};
      leagues.forEach(l => { leagueIdToName[l._id] = l.name; });
      gameObjs = games.map(g => ({
        _id: g._id,
        gameName: g.gameName || g.sport,
        leagueId: g.leagueId,
        leagueName: leagueIdToName[g.leagueId],
        teamAId: g.teamAId,
        teamAName: g.teamAName,
        teamBId: g.teamBId,
        teamBName: g.teamBName,
        scheduledDate: g.scheduledDate,
        location: g.location,
        status: g.status,
        sport: g.sport,
        tournamentId: g.tournamentId
      }));
    } else {
      // Admin/Player: See all games of teams the user is a member/admin of
      const user = await User.findOne({ username });
      if (!user) return res.status(404).json({ error: 'User not found' });
      if (Array.isArray(user.teams) && user.teams.length > 0) {
        teams = await Team.find({ _id: { $in: user.teams } });
      } else {
        teams = await Team.find({ members: username });
      }
      const teamIds = teams.map(t => t._id);
      games = await ScheduledGame.find({
        $or: [
          { teamAId: { $in: teamIds } },
          { teamBId: { $in: teamIds } }
        ]
      });
      // Find leagues for these teams
      const leagueIds = [
        ...new Set(
          teams.flatMap(team => Array.isArray(team.tournament) ? team.tournament : [team.tournament])
        )
      ].filter(Boolean);
      leagues = await Tournament.find({ _id: { $in: leagueIds } });
      leagueObjs = leagues.map(l => ({
        _id: l._id,
        name: l.name,
        sport: l.sport,
        region: l.region,
        status: l.status,
        teams: l.teams
      }));
      teamObjs = teams.map(t => ({
        _id: t._id,
        name: t.name,
        leagueId: t.tournament,
        sport: t.sport
      }));
      const leagueIdToName = {};
      leagues.forEach(l => { leagueIdToName[l._id] = l.name; });
      gameObjs = games.map(g => ({
        _id: g._id,
        gameName: g.gameName || g.sport,
        leagueId: g.leagueId,
        leagueName: leagueIdToName[g.leagueId],
        teamAId: g.teamAId,
        teamAName: g.teamAName,
        teamBId: g.teamBId,
        teamBName: g.teamBName,
        scheduledDate: g.scheduledDate,
        location: g.location,
        status: g.status,
        sport: g.sport,
        tournamentId: g.tournamentId
      }));
    }
    res.json({ leagues: leagueObjs, games: gameObjs, teams: teamObjs });
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch leagues, games, and teams' });
  }
});

// Endpoint: get all scheduled games for a specific league
app.get('/league/scheduled-games', async (req, res) => {
  const { leagueId } = req.query;
  if (!leagueId) return res.status(400).json({ error: 'Missing leagueId' });
  try {
    const games = await ScheduledGame.find({ leagueId });
    // Fetch the league name from Leagues collection using _id
    const league = await Leagues.findOne({ _id: leagueId });
    const leagueName = league ? league.name : leagueId;
    const result = games.map(g => ({
      gameName: g.gameName,
      leagueName: leagueName,
      teamAName: g.teamAName,
      teamBName: g.teamBName,
      teamAId: g.teamAId,
      teamBId: g.teamBId,
      scheduledDate: g.scheduledDate,
      location: g.location
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

// Endpoint to fetch members of a specific team
app.get('/team/members', async (req, res) => {
  const { teamId } = req.query;
  if (!teamId) return res.status(400).json({ error: 'Missing teamId' });
  try {
    const team = await Teams.findOne({ _id: teamId });
    if (!team) return res.status(404).json({ error: 'Team not found' });
    res.json({ members: team.members || [] });
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch team members' });
  }
});

// Endpoint to fetch player details by username
app.get('/player', async (req, res) => {
  const { username } = req.query;
  if (!username) return res.status(400).json({ error: 'Missing username' });
  try {
    // Find user by username
    const user = await User.findOne({ username });
    if (!user) return res.status(404).json({ error: 'Player not found' });
    // Example: teamName and contactNumber could be stored in user or another collection
    // Here, we assume they are in the user document
    res.json({
      username: user.username,
      teamName: user.teamName || '',
      contactNumber: user.contactNumber || ''
    });
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch player details' });
  }
});

// Endpoint to list all teams for registration
app.get('/teams/list', async (req, res) => {
  try {
    const teams = await Teams.find({}, '_id name sport');
    res.json({ teams });
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch teams' });
  }
});

app.listen(3000, '0.0.0.0', () => console.log('Backend running on http://0.0.0.0:3000'));
