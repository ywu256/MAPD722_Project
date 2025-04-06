// server.js

const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const Patient = require('./models/Patient');
const User = require('./models/user');
const bcrypt = require('bcrypt');
const Clinical = require('./models/Clinical');
const multer = require('multer');
const { Storage } = require('@google-cloud/storage');

const app = express();
const PORT = 3001;

app.use(cors());
app.use(express.json());

// Initialize GCP Storage
const storage = new Storage({
  keyFilename: './gcp-key.json',
  projectId: 'dauntless-gate-423902-a1',
});

// Define the bucket
const bucketName = 'mapd712';
const bucket = storage.bucket(bucketName);

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 5 * 1024 * 1024 }, // Limit the file size is 5MB
});

// Connect to patient_db
const patientDB = mongoose.createConnection('mongodb://localhost:27017/patient_db', {
  connectTimeoutMS: 20000,
});
const PatientModel = patientDB.model('Patient', Patient.schema);

// Get all patients
app.get('/patients', async (req, res) => {
  try {
    const patients = await PatientModel.find();
    res.json(patients);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Get a single patient with clinical data
app.get('/patients/:id', async (req, res) => {
  try {
    const patient = await PatientModel.findById(req.params.id);
    if (!patient) return res.status(404).json({ message: "Patient not found" });
    
    res.json({ patient });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Image upload route
app.post('/upload', upload.single('photo'), async (req, res) => {
  // Check if the file uploaded
  if (!req.file) {
      return res.status(400).json({ message: 'No photo uploaded' });
  }

  try {
    // Set the file name and its directory
    // patient-photos is a directory used to store patient's photo in the bucket of GCP
    const blob = bucket.file(`patient-photos/${Date.now()}-${req.file.originalname}`);

    // Create a write stream and upload the photo to GCP Storage
    const blobStream = blob.createWriteStream({
        metadata: {
            contentType: req.file.mimetype,
        },
    });

    // Handle the event if fail to upload the photo
    blobStream.on('error', (err) => {
        console.error('Upload error:', err);
        res.status(500).json({ message: 'Failed to upload the photo', error: err.message });
    });

    // Handle the event after finish uploading
    blobStream.on('finish', async () => {
        const publicUrl = `https://storage.googleapis.com/${bucketName}/${blob.name}`;
        res.status(200).json({ message: 'Photo uploaded successfully', url: publicUrl });
    });

    // Write the buffer of the photo to the stream
    blobStream.end(req.file.buffer);
  } catch (error) {
    console.error('Error uploading photo:', error);
    res.status(500).json({ message: 'Internal server error', error: error.message });
  }
});

// Add a new patient
app.post('/patients', async (req, res) => {
  // Get the values from body
  const {
    name,
    age,
    gender,
    admissionDate,
    condition,
    phone,
    email,
    address,
    emergencyContactPhone,
    medicalHistory,
    allergies,
    bloodType,
    photoUrl,
  } = req.body;

  try {
    // Check the latest patientId in db
    const lastPatient = await PatientModel.findOne().sort({ patientId: -1 });

    // Default patientId is PA001
    let newPatientId = "PA001";
    
    // The new patientID should be the latest patientId+1
    if (lastPatient) {
      const lastIdNumber = parseInt(lastPatient.patientId.slice(2), 10);
      const nextIdNumber = lastIdNumber + 1;

      newPatientId = `PA${String(nextIdNumber).padStart(3, '0')}`;
    }

    // Create a Patient object
    const newPatient = new PatientModel({
      patientId: newPatientId,
      name,
      age,
      gender,
      admissionDate,
      condition,
      phone,
      email,
      address,
      emergencyContactPhone,
      medicalHistory,
      allergies,
      bloodType,
      photoUrl,
    });

    // Store to database
    await newPatient.save();
    res.status(201).json({ message: 'Patient created successfully', patient: newPatient });
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// Update a patient
app.put('/patients/:id', async (req, res) => {
  const { id } = req.params;
  const {
    name,
    age,
    gender,
    condition,
    phone,
    email,
    address,
    emergencyContactPhone,
    medicalHistory,
    allergies,
    bloodType,
    photoUrl
  } = req.body;

  try {
    const updatedPatient = await PatientModel.findByIdAndUpdate(
      id,
      {
        name,
        age,
        gender,
        condition,
        phone,
        email,
        address,
        emergencyContactPhone,
        medicalHistory,
        allergies,
        bloodType,
        photoUrl
      },
      { new: true }
    );

    if (!updatedPatient) {
      return res.status(404).json({ message: "Patient not found." });
    }

    res.status(200).json({ message: "Patient updated successfully.", patient: updatedPatient });
  } catch (error) {
    console.error("Error updating patient:", error);
    res.status(500).json({ message: "Internal server error." });
  }
});

// Update just patient condition
app.patch('/patients/:id', async (req, res) => {
  const { id } = req.params;
  const { condition } = req.body;

  try {
    const updatedPatient = await PatientModel.findByIdAndUpdate(
      id,
      { condition },
      { new: true }
    );

    if (!updatedPatient) {
      return res.status(404).json({ message: "Patient not found." });
    }

    res.status(200).json({ 
      message: "Patient condition updated successfully.",
      patient: updatedPatient 
    });
  } catch (error) {
    console.error("Error updating patient condition:", error);
    res.status(500).json({ message: "Internal server error." });
  }
});

// Delete a patient by ID
app.delete('/patients/:id', async (req, res) => {
  const { id } = req.params;

  try {
    // Find the patient by ID and delete it
    const deletedPatient = await PatientModel.findByIdAndDelete(id);

    if (!deletedPatient) {
      // If the patient does not exist, return a 404 response
      return res.status(404).json({ message: 'Patient not found.' });
    }

    // Delete all clinical data associated with the patient
    await ClinicalModel.deleteMany({ patient_id: id });

    // Return a success response
    res.status(200).json({ message: 'Patient deleted successfully.' });
  } catch (error) {
    console.error('Error deleting patient:', error);
    // Handle any server errors
    res.status(500).json({ message: 'Internal server error.' });
  }
});

// Connect to user_db
const userDB = mongoose.createConnection('mongodb://localhost:27017/user_db');
const UserModel = userDB.model('User', User.schema);

app.post('/login', async (req, res) => {
  const { email, password } = req.body;

  try {
    // Search user
    const user = await UserModel.findOne({ email });
    if (!user) {
      return res.status(400).json({ message: "Invalid email" });
    }

    // Verify the password
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(400).json({ message: "Invalid password" });
    }

    // Login successfully
    return res.json({ message: "Login successful", user: { email: user.email, role: user.role } });
  } catch (err) {
    return res.status(500).json({ message: "Server error" });
  }
});

app.post('/reset-password', async (req, res) => {
  const { email, newPassword } = req.body;

  try {
    if (!email || !newPassword) {
      return res.status(400).json({ message: "Email and new password are required." });
    }

    const user = await UserModel.findOne({ email });
    if (!user) {
      return res.status(404).json({ message: "Email does not exist." });
    }

    const hashedPassword = await bcrypt.hash(newPassword, 10);

    user.password = hashedPassword;
    await user.save();

    res.status(200).json({ message: "Password reset successfully." });
  } catch (error) {
    console.error("Error resetting password:", error);
    res.status(500).json({ message: "Internal server error." });
  }
});

// Connect to user_db
const clinicalDB = mongoose.createConnection('mongodb://localhost:27017/clinical_db');
const ClinicalModel = clinicalDB.model('Clinical', Clinical.schema);

// Add a new clinical measurement
app.post('/clinical', async (req, res) => {
  const { patient_id, type, value } = req.body;

  const newClinical = new ClinicalModel({
    ...req.body,
  });

  try {
    await newClinical.save();

    // Define abnormal value thresholds
    const abnormalThresholds = {
      'Blood Pressure': (val) => {
        const [systolic, diastolicWithUnit] = val.split('/');
        const diastolic = diastolicWithUnit.split(' ')[0];

        return Number(systolic) > 180 || Number(systolic) < 90 || Number(diastolic) > 120 || Number(diastolic) < 60;
      },
      'Respiratory Rate': (val) => {
        const rate = val.split(' ')[0];
        return Number(rate) < 12 || Number(rate) > 20;
      },
      'HeartBeat Rate': (val) => {
        const rate = val.split(' ')[0];

        return Number(rate) < 60 || Number(rate) > 100;
      },
      'Blood Oxygen Level': (val) => {
        const rate = val.split(' ')[0];

        return Number(rate) < 90;
      },
    };

    // Check if the measurement is abnormal
    const isAbnormal = abnormalThresholds[type] && abnormalThresholds[type](value);

    if (isAbnormal) {
      // Update the patient's condition to "Critical" if the value is abnormal
      const patient = await PatientModel.findByIdAndUpdate(
        patient_id,
        { condition: 'Critical' },
        { new: true }
      );

      if (!patient) {
        return res.status(404).json({ message: 'Patient not found.' });
      }
    }

    res.status(201).json(newClinical);
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
});

// Get clinical measurements for a specific patient
app.get('/clinical/:patientId', async (req, res) => {
  const { patientId } = req.params;

  try {
    // Search the specific patient's measurement data
    const clinicalData = await ClinicalModel.find({ patient_id: new mongoose.Types.ObjectId(patientId) });

    res.status(200).json(clinicalData);
  } catch(error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
});

// Start the server
app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});
