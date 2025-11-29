const express = require("express");
const cors = require("cors");
const { MongoClient, ObjectId } = require("mongodb");
const nodemailer = require("nodemailer");
const multer = require("multer");
const path = require("path");
const fs = require("fs");

const app = express();
app.use(cors({ origin: "*", methods: ["GET", "POST"] }));
app.use(express.json());

// Make uploads folder if not exists
const uploadDir = path.join(__dirname, "uploads");
if (!fs.existsSync(uploadDir)) fs.mkdirSync(uploadDir);

// Static folder to serve images
app.use("/uploads", express.static(uploadDir));

// Multer storage settings
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, "uploads/");
  },
  filename: function (req, file, cb) {
    const ext = path.extname(file.originalname);
    cb(null, Date.now() + ext);
  },
});
const upload = multer({ storage });

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
  const products = db.collection("products");
  const Cart = db.collection("cart");

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

  // ===================== FORGOT PASSWORD =====================
  app.post("/send-forgot-otp", async (req, res) => {
    try {
      const { email } = req.body;
      const normalizedEmail = email.trim().toLowerCase();
      const user = await users.findOne({ email: normalizedEmail });
      if (!user)
        return res.status(400).json({ message: "Email not registered" });

      const otp = Math.floor(100000 + Math.random() * 900000).toString();
      otps[normalizedEmail] = { otp, email: normalizedEmail };

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

  app.post("/verify-forgot-otp", async (req, res) => {
    try {
      const { email, otp } = req.body;
      const normalizedEmail = email.trim().toLowerCase();

      if (!otps[normalizedEmail])
        return res.status(400).json({ message: "No OTP found for this email" });

      if (otps[normalizedEmail].otp !== otp.trim())
        return res.status(400).json({ message: "Invalid OTP" });

      delete otps[normalizedEmail];
      return res.status(200).json({ message: "OTP verified" });
    } catch (err) {
      console.error(err);
      return res.status(500).json({ message: "Server error" });
    }
  });

  app.post("/reset-password", async (req, res) => {
    try {
      const { email, newPassword } = req.body;
      const normalizedEmail = email.trim().toLowerCase();

      const user = await users.findOne({ email: normalizedEmail });
      if (!user) return res.status(400).json({ message: "Email not found" });

      await users.updateOne(
        { email: normalizedEmail },
        { $set: { password: newPassword } }
      );
      return res.status(200).json({ message: "Password updated successfully" });
    } catch (err) {
      console.error(err);
      return res
        .status(500)
        .json({ message: "Server error", error: err.toString() });
    }
  });

  // ===================== ADD PRODUCT =====================
  app.post("/add-product", upload.single("image"), async (req, res) => {
    try {
      const { sellerId, productName, description, category, price } = req.body;
      if (!sellerId || !productName || !price)
        return res.status(400).json({ message: "Missing required fields" });

      const imageUrl = req.file ? `/uploads/${req.file.filename}` : "";

      const result = await products.insertOne({
        sellerId,
        productName,
        description,
        category,
        price,
        imageUrl,
        createdAt: new Date(),
      });

      return res
        .status(200)
        .json({ message: "Product added", productId: result.insertedId });
    } catch (err) {
      console.error(err);
      return res
        .status(500)
        .json({ message: "Server error", error: err.toString() });
    }
  });

  // ===================== GET PRODUCTS BY SELLER =====================
  app.get("/get-products/:sellerId", async (req, res) => {
    try {
      const { sellerId } = req.params;

      // Ensure sellerId is a string (matches what is stored in products)
      const sellerProducts = await products
        .find({ sellerId: sellerId }) // filter by the seller
        .toArray();

      return res.status(200).json({ products: sellerProducts });
    } catch (err) {
      console.error(err);
      return res.status(500).json({ message: "Server error" });
    }
  });
  // ===================== DELETE PRODUCT =====================
  app.delete("/delete-product/:productId", async (req, res) => {
    try {
      const { productId } = req.params;

      // Find the product first
      const product = await products.findOne({ _id: new ObjectId(productId) });
      if (!product)
        return res.status(404).json({ message: "Product not found" });

      // Delete the image file if it exists
      if (product.imageUrl) {
        const imagePath = path.join(__dirname, product.imageUrl);
        if (fs.existsSync(imagePath)) {
          fs.unlinkSync(imagePath); // delete file
        }
      }

      // Delete product from database
      await products.deleteOne({ _id: new ObjectId(productId) });

      return res.status(200).json({ message: "Product deleted successfully" });
    } catch (err) {
      console.error(err);
      return res.status(500).json({ message: "Server error" });
    }
  });

  // ===================== UPDATE PRODUCT =====================

  app.put(
    "/update-product/:productId",
    upload.single("image"),
    async (req, res) => {
      try {
        const { productId } = req.params;
        const { productName, description, category, price } = req.body;

        const updateData = {};
        if (productName) updateData.productName = productName;
        if (description) updateData.description = description;
        if (category) updateData.category = category;
        if (price) updateData.price = price;
        if (req.file) updateData.imageUrl = `/uploads/${req.file.filename}`;

        await products.updateOne(
          { _id: new ObjectId(productId) },
          { $set: updateData }
        );
        return res
          .status(200)
          .json({ message: "Product updated successfully" });
      } catch (err) {
        console.error(err);
        return res.status(500).json({ message: "Server error" });
      }
    }
  );
  // ===================== GET SELLER DETAILS =====================
  app.get("/get-seller/:userId", async (req, res) => {
    try {
      const { userId } = req.params;

      const user = await users.findOne({ _id: new ObjectId(userId) });

      if (!user) return res.status(404).json({ message: "User not found" });

      return res.status(200).json({
        name: user.name,
        email: user.email,
        role: user.role,
        cnic: user.cnic || "",
        bankName: user.bankName || "",
        bankAccount: user.bankAccount || "",
        shopName: user.shopName || "",
        imageUrl: user.imageUrl || "",
      });
    } catch (err) {
      console.error(err);
      return res.status(500).json({ message: "Server error" });
    }
  });
  // ===================== UPDATE SELLER PROFILE =====================
  app.put(
    "/update-seller/:userId",
    upload.single("image"), // image is optional
    async (req, res) => {
      try {
        const { userId } = req.params;
        const { name, shopName, cnic, bankName, bankAccount } = req.body;

        const updateData = {};
        if (name) updateData.name = name;
        if (shopName) updateData.shopName = shopName;
        if (cnic) updateData.cnic = cnic;
        if (bankName) updateData.bankName = bankName;
        if (bankAccount) updateData.bankAccount = bankAccount;

        // Handle profile image
        if (req.file) {
          const imageUrl = `/uploads/${req.file.filename}`;
          updateData.imageUrl = imageUrl;

          // Optional: delete old image
          const user = await users.findOne({ _id: new ObjectId(userId) });
          if (user?.imageUrl) {
            const oldImagePath = path.join(__dirname, user.imageUrl);
            if (fs.existsSync(oldImagePath)) fs.unlinkSync(oldImagePath);
          }
        }

        await users.updateOne(
          { _id: new ObjectId(userId) },
          { $set: updateData }
        );

        const updatedUser = await users.findOne({ _id: new ObjectId(userId) });

        return res.status(200).json({
          message: "Profile updated successfully",
          user: {
            name: updatedUser.name,
            shopName: updatedUser.shopName,
            cnic: updatedUser.cnic || "",
            bankName: updatedUser.bankName || "",
            bankAccount: updatedUser.bankAccount || "",
            imageUrl: updatedUser.imageUrl || "",
          },
        });
      } catch (err) {
        console.error(err);
        return res
          .status(500)
          .json({ message: "Server error", error: err.toString() });
      }
    }
  );
  // ===================== GET ALL PRODUCTS =====================
  // ===================== GET ALL PRODUCTS WITH STORE INFO =====================
  app.get("/get-products", async (req, res) => {
    try {
      const allProducts = await products.find({}).toArray();

      // Add store info to each product
      const productsWithStore = await Promise.all(
        allProducts.map(async (product) => {
          const seller = await users.findOne({
            _id: new ObjectId(product.sellerId),
          });
          return {
            ...product,
            store: seller
              ? {
                  _id: seller._id.toString(),
                  name: seller.shopName || seller.name,
                }
              : {},
          };
        })
      );

      return res.status(200).json({ products: productsWithStore });
    } catch (err) {
      console.error(err);
      return res.status(500).json({ message: "Server error" });
    }
  });
  app.post("/add-to-cart", async (req, res) => {
  try {
    const { userId, product } = req.body;

    if (!product) {
      return res.status(400).json({ message: "Product data missing" });
    }

    const db = client.db("beadaura");
    const cart = db.collection("cart");

    await cart.insertOne({
      userId: userId || null,   // store userId if provided, else null
      product,
      createdAt: new Date(),
    });

    return res.status(200).json({ message: "Added to cart" });
  } catch (err) {
    console.log("Cart error:", err);
    return res.status(500).json({ message: "Failed to add to cart" });
  }
});


  app.get("/cart/:userId", async (req, res) => {
    try {
      const cartItems = await Cart.find({
        userId: req.params.userId,
      }).toArray();
      res.json({ cartItems });
    } catch (err) {
      res.status(500).json({ success: false, error: err.message });
    }
  });
  // DELETE cart item
  app.delete("/delete-cart-item/:cartItemId", async (req, res) => {
    try {
      const { cartItemId } = req.params;
      await Cart.deleteOne({ _id: new ObjectId(cartItemId) });
      res.status(200).json({ message: "Cart item removed" });
    } catch (err) {
      console.error(err);
      res.status(500).json({ message: "Server error" });
    }
  });

  // Start server
  app.listen(PORT, "0.0.0.0", () =>
    console.log(`Server running on port ${PORT}`)
  );
}

startServer();
