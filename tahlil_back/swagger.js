const swaggerJSDoc = require('swagger-jsdoc');

const options = {
    definition: {
        openapi: '3.0.0',
        info: {
            title: 'Pezeshkan-sharif',
            version: '1.0.0',
        },
    },
    apis: ['./routes/*/**.js', './routes/*.js'], // Path to the API routes
};
const swaggerSpec = swaggerJSDoc(options);
module.exports = swaggerSpec;
