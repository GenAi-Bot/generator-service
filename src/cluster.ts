import cluster from "cluster";
import { cpus } from "os";

const workers = cpus().length;

if (cluster.isPrimary) {
    for (let i = 0; i < workers; i++) {
        cluster.fork();
    }

    cluster.on("exit", () => {
        cluster.fork();
    });
} else {
    require("./app");
}