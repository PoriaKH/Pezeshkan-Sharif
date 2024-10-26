const multer = require("multer");
const path = require("path");
const fs = require('fs');

const pfp_storage = multer({
    storage: multer.diskStorage({
        destination: (req, file, cb) => {
            const dir = `files/profile-pictures/`
            if (!fs.existsSync(dir))
                fs.mkdirSync(dir, {recursive: true});
            cb(null, dir);
        },
        filename: (req, file, cb) => cb(null, req.ssid + path.extname(file.originalname)),
    })
});

const opg_images_storage = multer({
    storage: multer.diskStorage({
        destination: (req, file, cb) => {
            const dir = `files/opg-images/${req.params['id']}/`
            if (!fs.existsSync(dir))
                fs.mkdirSync(dir, {recursive: true});
            cb(null, dir);
        },
        filename: (req, file, cb) => cb(null, new Date().getTime() + path.extname(file.originalname)),
    })
});

const delete_file = (filename) => fs.unlink(filename, console.log);

module.exports = {pfp_storage, opg_images_storage, delete_file}