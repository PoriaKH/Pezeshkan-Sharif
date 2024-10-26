const {validateJwtToken} = require('../../utils/jwt')

const auth_midware = (db, allowed_types = ['doctor', 'patient', 'referrer', 'imaging_center']) => async (req, res, next) => {
    let {token} = req.cookies;

    const {rows} = await db.query(`select * from public."login_token" where token='${token}' order by created_at desc limit 1`);
    if (rows.length === 0) return res.status(401).send('Invalid Token!')
    const {ssid, created_at, user_type} = rows[0]
    if (!validateJwtToken(token)) {
        res.status(401).send('Invalid Token!')
    } else if ((new Date()).getTime() - created_at.getTime() >= process.env.cookie_max_age) {
        res.status(401).send('Old Token! Send a GET /auth/refresh request and try again.')
    } else if (!allowed_types.includes(user_type)) {
        res.status(401).send(`${user_type} is not allowed for this operation!`)
    } else {
        req.ssid = ssid;
        next();
    }
};

module.exports = {auth_midware};