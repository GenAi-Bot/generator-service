export const emojiRegexp = /<(a)?:\w{2,32}:\d{17,19}>/gi;
export const urlRegexp = /https?:\/\/[^\s]+/gi;

export function getRandomElement(array: any[]) {
    return array[Math.floor(Math.random() * array.length)];
}

export function getRandomKey(object: Record<string, any>) {
    const keys = Object.keys(object);
    return getRandomElement(keys);
}
