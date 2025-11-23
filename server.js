const express = require("express");
const cors = require("cors");
const { MongoClient } = require("mongodb");
const nodemailer = require("nodemailer");

const app = express();
app.use(cors({ origin: "*", methods: ["GET", "POST"] }));
app.use(express.json());

// MongoDB
const uri =
  "mongodb+srv://fatimarashid312_db_user:b3uuBaZyml7B3u0f@cluster0.pvmvetz.mongodb.net/beadaura?retryWrites=true&w=majority";
const client = new MongoClient(uri);
const PORT = 3000;

// Email transporter
const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: "beadaura23@gmail.com",
    pass: "lsvb fqoi hyse vgxs",
  },
});

// Store OTPs temporarily
const otps = {};

async function startServer() {
  await client.connect();
  console.log("Connected to MongoDB");

  const db = client.db("beadaura");
  const users = db.collection("users");

  await users.createIndex({ email: 1 }, { unique: true });

  // ===================== SIGNUP =====================
  app.post("/signup", async (req, res) => {
    try {
      const {
        name,
        email,
        password,
        role,
        cnic,
        bankAccount,
        bankName,
        shopName,
      } = req.body;

      const normalizedEmail = email.trim().toLowerCase();

      const existing = await users.findOne({ email: normalizedEmail });
      if (existing)
        return res.status(400).json({ message: "Email already exists" });

      // Generate OTP
      const otp = Math.floor(100000 + Math.random() * 900000).toString();

      otps[normalizedEmail] = {
        otp,
        userData: {
          name,
          email: normalizedEmail,
          password,
          role,
          ...(role === "seller" && {
            cnic,
            bankAccount,
            bankName,
            shopName,
          }),
        },
      };

      // Send email
      await transporter.sendMail({
        from: '"BeadAura" <beadaura23@gmail.com>',
        to: normalizedEmail,
        subject: "BeadAura OTP Verification",
        html: `<h2>Your OTP is: <b>${otp}</b></h2>`,
      });

      console.log("OTP sent to", normalizedEmail, ":", otp);

      return res.status(200).json({ message: "OTP sent" });
    } catch (error) {
      console.error(error);
      return res.status(500).json({ message: "Server error" });
    }
  });

  // ===================== VERIFY OTP =====================
  app.post("/verify-otp", async (req, res) => {
    try {
      const { email, otp } = req.body;
      const normalizedEmail = email.trim().toLowerCase();

      if (!otps[normalizedEmail])
        return res.status(400).json({ message: "No OTP found for email" });

      if (otps[normalizedEmail].otp !== otp.trim())
        return res.status(400).json({ message: "Invalid OTP" });

      // Insert user
      const result = await users.insertOne({
        ...otps[normalizedEmail].userData,
        isVerified: true,
      });

      const user = await users.findOne({ _id: result.insertedId });

      delete otps[normalizedEmail];

      return res.status(200).json({
        message: "Signup complete",
        userId: user._id.toString(),
        name: user.name,
        role: user.role,
        email: user.email,
      });
    } catch (err) {
      console.error(err);
      return res.status(500).json({ message: "Server error" });
    }
  });

  // ===================== LOGIN =====================
  app.post("/login", async (req, res) => {
    try {
      const { email, password } = req.body;
      const normalizedEmail = email.trim().toLowerCase();

      const user = await users.findOne({ email: normalizedEmail });

      if (!user || user.password !== password)
        return res.status(400).json({ message: "Invalid email or password" });

      return res.status(200).json({
        message: "Login successful",
        userId: user._id.toString(),
        name: user.name,
        role: user.role,
        email: user.email,
      });
    } catch (err) {
      console.error(err);
      return res.status(500).json({ message: "Server error" });
    }
  });
  // ===================== SEND FORGOT PASSWORD OTP =====================
  app.post("/send-forgot-otp", async (req, res) => {
    try {
      const { email } = req.body;
      const normalizedEmail = email.trim().toLowerCase();

      const user = await users.findOne({ email: normalizedEmail });
      if (!user) {
        return res.status(400).json({ message: "Email not registered" });
      }

      // Generate OTP
      const otp = Math.floor(100000 + Math.random() * 900000).toString();
      otps[normalizedEmail] = { otp, email: normalizedEmail };

      // Send OTP email
      await transporter.sendMail({
        from: '"BeadAura" <beadaura23@gmail.com>',
        to: normalizedEmail,
        subject: "BeadAura Password Reset OTP",
        html: `<h2>Your password reset OTP is: <b>${otp}</b></h2>`,
      });

      console.log("Forgot password OTP sent to", normalizedEmail, ":", otp);

      return res.status(200).json({ message: "OTP sent to your email" });
    } catch (error) {
      console.error(error);
      return res
        .status(500)
        .json({ message: "Server error", error: error.toString() });
    }
  });

  // ===================== VERIFY FORGOT PASSWORD OTP =====================
  app.post("/verify-forgot-otp", async (req, res) => {
    try {
      const { email, otp } = req.body;
      const normalizedEmail = email.trim().toLowerCase();

      if (!otps[normalizedEmail]) {
        return res.status(400).json({ message: "No OTP found for this email" });
      }

      if (otps[normalizedEmail].otp !== otp.trim()) {
        return res.status(400).json({ message: "Invalid OTP" });
      }

      // OTP is valid, remove it
      delete otps[normalizedEmail];

      return res.status(200).json({ message: "OTP verified" });
    } catch (err) {
      console.error(err);
      return res.status(500).json({ message: "Server error" });
    }
  });

  // ===================== RESET PASSWORD =====================
  app.post("/reset-password", async (req, res) => {
    try {
      const { email, newPassword } = req.body;
      const normalizedEmail = email.trim().toLowerCase();

      // Find the user first
      const user = await users.findOne({ email: normalizedEmail });
      if (!user) {
        console.log("Email not found in DB:", normalizedEmail);
        return res.status(400).json({ message: "Email not found" });
      }

      console.log("Current user password:", user.password);

      // Update password
      const result = await users.updateOne(
        { email: normalizedEmail },
        { $set: { password: newPassword } }
      );

      console.log("Update result:", result);

      return res.status(200).json({ message: "Password updated successfully" });
    } catch (err) {
      console.error(err);
      return res
        .status(500)
        .json({ message: "Server error", error: err.toString() });
    }
  });

  // Start server
  app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
}

startServer();
