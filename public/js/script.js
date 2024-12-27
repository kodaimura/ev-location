export const getJaTime = () => {
    const date = new Date();
    const utcOffset = date.getTimezoneOffset() * 60000;
    const jaTime = new Date(date.getTime() + utcOffset + 9 * 3600000);
    return jaTime;
};