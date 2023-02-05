export abstract class AbstractDataKeeper {
    public abstract get(channelID: string, removeLinks: boolean): Promise<string[]> | string[];
}