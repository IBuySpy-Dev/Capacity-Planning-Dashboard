# Next.js — Server Components & Data Fetching

## Server Components (Default)

Use Server Components for all components that don't require interactivity.

```tsx
export default async function UserProfile({ id }: { id: string }) {
  const user = await fetchUser(id);
  return <div><h1>{user.name}</h1></div>;
}
```

For interactivity, add `"use client"` directive.

## RSC Data Fetching

```tsx
// ✓ Good: Direct server-side fetch or ORM in Server Component
export default async function Users() {
  const users = await db.user.findMany();
  return <ul>{users.map(u => <li key={u.id}>{u.name}</li>)}</ul>;
}

// ✗ Avoid: Client-side fetch with useEffect
"use client";
export default function Users() {
  const [users, setUsers] = useState([]);
  useEffect(() => { fetch('/api/users').then(r => r.json()).then(setUsers); }, []);
}
```

## use() Hook (pass async data to Client Components)

```tsx
import { use } from "react";

function UserDetailsClient({ userPromise }: { userPromise: Promise<User> }) {
  const user = use(userPromise);
  return <div>{user.name}</div>;
}

export default function UserLayout({ id }: { id: string }) {
  return <UserDetailsClient userPromise={getUser(id)} />;
}
```

## Cache & Revalidation

```tsx
export const revalidate = 3600; // route-level

// On-demand
revalidatePath(`/posts/${id}`);
revalidateTag("posts");

// fetch with caching
const res = await fetch(url, { next: { revalidate: 3600, tags: ["posts"] } });
```
