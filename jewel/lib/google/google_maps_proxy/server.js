const express = require('express');
const axios = require('axios');
const cors = require('cors');
const app = express();
const port = 3000;

app.use(cors());

app.get('/distance-matrix', async (req, res) => {
  const { apiKey, origin, destination } = req.query;

  console.log(`Received origin: ${origin}`);
  console.log(`Received destination: ${destination}`);

  if (!apiKey) {
    return res.status(400).send('API key is required');
  }

  try {
    const response = await axios.get('https://maps.googleapis.com/maps/api/distancematrix/json', {
      params: {
        units: 'metric',
        origins: origin,
        destinations: destination,
        key: apiKey,
      },
    });

    res.json(response.data);
  } catch (error) {
    console.error('Error fetching distance matrix:', error);
    res.status(500).send('Error fetching distance matrix');
  }
});

app.listen(port, () => {
  console.log(`Server running at http://localhost:${port}`);
});