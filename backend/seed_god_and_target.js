// Seed script: creates a god_admin user and a target user, then prints a JWT for the god admin
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
require('dotenv').config();

const JWT_SECRET = process.env.JWT_SECRET || 'your_jwt_secret';

const userSchema = new mongoose.Schema({
  firstName: String,
  lastName: String,
  email: { type: String, unique: true },
  password: String,
  contactNumber: String,
  profileId: { type: String, unique: true },
  god_admin: Boolean,
  roles: Array,
});
const User = mongoose.model('User', userSchema);

async function main() {
  await mongoose.connect('mongodb://localhost:27017/scorer');
  console.log('Connected to MongoDB');

  const godEmail = 'god@example.com';
  const targetEmail = 'target@example.com';

  const godPassword = bcrypt.hashSync('password', 10);
  const targetPassword = bcrypt.hashSync('password', 10);

  const god = await User.findOneAndUpdate(
    { email: godEmail },
    {
      $set: {
        firstName: 'God',
        lastName: 'Admin',
        email: godEmail,
        password: godPassword,
        profileId: 'GOD001',
        god_admin: true,
        roles: [{ leagueId: null, teamId: null, role: 'player' }],
      },
    },
    { upsert: true, new: true, setDefaultsOnInsert: true }
  );

  const target = await User.findOneAndUpdate(
    { email: targetEmail },
    {
      $set: {
        firstName: 'Target',
        lastName: 'User',
        email: targetEmail,
        password: targetPassword,
        profileId: 'TGT001',
        god_admin: false,
        roles: [
          { leagueId: 'L1', teamId: 'T1', role: 'admin' },
          { leagueId: null, teamId: null, role: 'player' },
        ],
      },
    },
    { upsert: true, new: true, setDefaultsOnInsert: true }
  );

  const token = jwt.sign({ email: god.email }, JWT_SECRET, { expiresIn: '1h' });

  console.log(JSON.stringify({
    god: { id: god._id.toString(), email: god.email },
    target: { id: target._id.toString(), email: target.email, roles: target.roles },
    token
  }, null, 2));

  await mongoose.disconnect();
}

main().catch(err => { console.error(err); process.exit(1); });

