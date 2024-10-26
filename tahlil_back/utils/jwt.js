const jwt = require("jsonwebtoken");

function generateJwtToken(ssid) {
    let jwtSecretKey = process.env.jwt_secret_key;
    let data = {
        time: Date(),
        ssid: ssid,
    }

    return jwt.sign(data, jwtSecretKey);
}

function validateJwtToken(token) {
    try {
        let jwtSecretKey = process.env.jwt_secret_key;
        return jwt.verify(token, jwtSecretKey);
    } catch (error) {
        return false
    }
}

module.exports = {validateJwtToken, generateJwtToken};