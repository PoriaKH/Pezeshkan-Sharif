const nodemailer = require('nodemailer');

async function scheduleMail(patient_ssid, appointment_id, db) {
    let patient, appointment;

    await db.query({text: 'select * from public."patient" where ssid=$1', values: [patient_ssid]})
        .then(({rows}) => patient = rows[0])
        .catch(console.log);

    await db.query({
        text: 'select * from public."doctor_appointment_v1" a where a.id=$1',
        values: [appointment_id]
    })
        .then(({rows}) => appointment = rows[0])
        .catch(console.log);
    if (!appointment)
        await db.query({
            text: 'select * from public."imaging_center_appointment_v1" a where a.id=$1',
            values: [appointment_id]
        })
            .then(({rows}) => appointment = rows[0])
            .catch(console.log);

    const appointment_with = appointment['doctor'] ?
        (appointment['doctor_first_name'] + " " + appointment['doctor_last_name']) :
        appointment['imaging_center_name'];
    const date_time = appointment['date_time'];
    const time_str = `${date_time.toDateString()} ${date_time.getHours()}:00`;
    const link = `https://pezeshkan-sharif-front.liara.run/#/appointment/${appointment_id}`;
    const html = `<h1>Hello ${patient['first_name']} ${patient['last_name']}.</h1>` +
        `<p>We would like to remind you for your appointment with "${appointment_with}" at ${time_str}.<br/>` +
        `You can view your appointment <a href="${link}">here</a><br/><br/>` +
        `Best Regards,<br/>` +
        `The Pezeshkan-sharif team</p>`;
    const send_time = new Date(date_time.getTime() - 24 * 60 * 60 * 1000);

    const transport = nodemailer.createTransport({
        service: 'gmail',
        auth: {
            user: process.env.gmail_address,
            pass: process.env.gmail_password,
        }
    })
    const mail_options = {
        from: process.env.gmail_address,
        to: patient['email_address'],
        subject: `Appointment Reminder with ${appointment_with} at ${time_str}`,
        html: html,
        date: (send_time.getTime() - new Date() <= 0) ? new Date() : date_time,
    }
    await transport.sendMail(mail_options);
}

module.exports = scheduleMail;