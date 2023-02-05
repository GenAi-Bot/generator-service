export function removeURLs(str: string): string {
    return str.replace(/https?:\/\/[^\s]+/g, "");
}