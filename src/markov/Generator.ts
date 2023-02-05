import { defaultValidator, Validator } from "./Validators";
import { defaultFormatter, Formatter } from "./Formatters";
import { urlRegexp, getRandomKey } from "./utils";

const start = "__start";
const end = "__end";

interface GenerateOptions {
    attempts?: number;
    begin?: string;
    validator?: Validator;
    formatter?: Formatter;
}

export class StringGenerator {
    private frames: string[] = [];
    private model: Record<string, Record<string, number>> = {};
    constructor(samples: string[]) {
        if (!samples.length) {
            throw new Error("array is empty");
        }

        for (const sample of samples) {
            const words = sample.split(" ");     
            
            this.frames.push(start);

            for (const word of words) {
                if (!word || !word.length) continue;
                if (word.startsWith("http")) {
                    if (urlRegexp.test(word)) this.frames.push(word);
                    else this.frames.push(word.toLowerCase());
                    continue;
                } else {
                    this.frames.push(word.toLowerCase());
                }
            }

            words.length = 0;

            this.frames.push(end);
        }

        for (let i = 0; i < this.frames.length; i++) {
            const currentFrame = this.frames[i];
            const nextFrame = this.frames[i + 1];

            if (!nextFrame) {
                break;
            }
            
            if (currentFrame in this.model) {
                try {
                    if (nextFrame in this.model[currentFrame]) {
                        this.model[currentFrame][nextFrame] += 1;
                    } else {
                        this.model[currentFrame][nextFrame] = 1;
                    }
                } catch { }
            } else {
                this.model[currentFrame] = {};
                this.model[currentFrame][nextFrame] = 1;
            }
        }
    }

    generate({
        attempts = 1,
        begin,
        validator,
        formatter
    }: GenerateOptions = {}): string | undefined {
        if (begin) {
            begin = `${start} ${begin}`;
        } else {
            begin = start;
        }

        if (!validator) {
            validator = defaultValidator();
        }

        if (!formatter) {
            formatter = defaultFormatter;
        }

        let beginningFrames = begin.split(" ");

        for (let i = 0; i < attempts; i++) {
            let result = Array.from(beginningFrames);
            let currentFrame = result[result.length - 1];

            while (currentFrame != end) {
                let availableNextFrames = { ...this.model[currentFrame] };

                if (!Object.keys(availableNextFrames).length) {
                    throw new Error(`Not enough samples to use ${beginningFrames.slice(1).join(" ")} as beginning argument`);
                }

                let nextFrame = getRandomKey(availableNextFrames);

                if (!nextFrame) {
                    nextFrame = end;
                }

                result.push(nextFrame);
                currentFrame = nextFrame;
            }            

            result.splice(result.indexOf(start), 1);
            result.splice(result.indexOf(end), 1);

            let stringResult = result.join(" ");
            
            if (validator(stringResult)) {  
                return formatter(stringResult);
            }
        }

        return;
    }

    clear() {
        this.frames.length = 0;
        this.model = {};

        return this;
    }
}
