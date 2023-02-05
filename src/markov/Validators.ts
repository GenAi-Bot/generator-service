export type Validator = (value: string) => boolean;

export function defaultValidator(): Validator {
    return (value: string) => true;
};

export function wordsCount(min: number, max: number): Validator {
    if (!min && !max) {
        throw new Error("minimal and maximal cannot be both unspecified");
    }

    if (!min) {
        min = 0;
    }

    if (!max) {
        max = Infinity;
    }

    return (phrase) => min <= phrase.split(" ").length && phrase.split(" ").length <= max;
}

export function symbolsCount(min: number, max: number): Validator {
    if (!min && !max) {
        throw new Error("minimal and maximal cannot be both unspecified");
    }

    if (!min) {
        min = 0;
    }

    if (!max) {
        max = Infinity;
    }        

    return (phrase) => min <= phrase.length && phrase.length <= max;
}