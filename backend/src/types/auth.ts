export type UserRole = "viewer" | "creator" | "admin";

export interface AuthUser {
  id: string;
  role: UserRole;
}
