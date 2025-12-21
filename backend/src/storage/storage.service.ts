import { LocalStorageProvider } from "./local.storage";
import { R2StorageProvider } from "./r2.storage";
import { StorageProvider } from "./storage.interface";

let storageProvider: StorageProvider;

if (process.env.STORAGE_PROVIDER === "r2") {
  storageProvider = new R2StorageProvider();
} else {
  storageProvider = new LocalStorageProvider();
}

export { storageProvider };
