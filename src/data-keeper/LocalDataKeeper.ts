import { AbstractDataKeeper } from "./AbstractDataKeeper";
import { promises as fs, existsSync } from "fs";
import { join } from "path";
import { removeURLs } from "../helpers";

export class LocalDataKeeper extends AbstractDataKeeper {
    private readonly messagesPath: string;

    constructor(messagesPath: string) {
        super();
        this.messagesPath = messagesPath;
    }

    private getFilePath(channelID: string): string {
        return join(this.messagesPath, channelID + ".txt");
    }

    private fileExists(channelID: string): boolean {
        return existsSync(this.getFilePath(channelID));
    }


    public async get(channelID: string, removeLinks = false): Promise<string[]> {
        if (!this.fileExists(channelID)) return Promise.resolve([]);

        const lines = [];
        const file = await fs.open(this.getFilePath(channelID));

        for await (const line of file.readLines()) {
            if (removeLinks) {
                const removed = removeURLs(line).trim();
                if (removed.length > 0) lines.push(removed);
            } else {
                lines.push(line);
            }
        }

        await file.close();
        return lines;
    }
}