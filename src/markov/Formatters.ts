import { getRandomElement, urlRegexp, emojiRegexp } from "./utils";

export type Formatter = (str: string) => string;

export const defaultFormatter: Formatter = (str) => str;

export const caps: Formatter = (str) => str.split(" ")
    .map(s => urlRegexp.test(s) ? s : s.toUpperCase())
    .join(" ")
    .replace(emojiRegexp, x => x.toLowerCase());

export function usualSyntax(result: string): string {
    let formattedResult = "";

    for (let i = 0; i < result.length; i++) {
        if (i === 0 && result.slice(0, 4) !== "http") {
            formattedResult += result[i].toUpperCase();
            continue;
        }

        if (i > 1) {
            if (result[i - 1] === " " && [".", "?", "!"].includes(result[i - 2])) {
                formattedResult += result[i].toUpperCase();
            } else {
                formattedResult += result[i];
            }
        } else {
            formattedResult += result[i];
        }
    }
    
    if (![".", "?", "!"].includes(formattedResult[formattedResult.length - 1])) {
        formattedResult += getRandomElement([".", "?", "!", "..."]);
    }

    return formattedResult;
}