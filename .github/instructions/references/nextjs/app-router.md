# Next.js — App Router, Server Actions & Performance

## App Router Structure

```
app/
  layout.tsx          # Root layout
  page.tsx            # Home page
  dashboard/
    layout.tsx
    page.tsx
    @analytics/page.tsx  # Parallel route slot
  api/users/route.ts  # Route Handler
```

## Route Handlers

```tsx
// app/api/posts/route.ts
export async function GET(request: NextRequest) {
  return NextResponse.json(await db.posts.findMany());
}
export async function POST(request: NextRequest) {
  const post = await db.posts.create(await request.json());
  return NextResponse.json(post, { status: 201 });
}

// app/api/posts/[id]/route.ts
export async function DELETE(request: NextRequest, { params }: { params: { id: string } }) {
  await db.posts.delete({ where: { id: params.id } });
  return new NextResponse(null, { status: 204 });
}
```

## Server Actions

```tsx
"use server";
export async function updateProfile(formData: FormData) {
  const name = formData.get("name");
  const email = formData.get("email");
  if (!name || !email) return { error: "Name and email are required" };
  await db.user.update({ where: { id: String(formData.get("userId")) }, data: { name: String(name), email: String(email) } });
  revalidatePath("/profile");
  return { success: true };
}
```

Client Component with `useActionState`:

```tsx
"use client";
const [state, formAction, isPending] = useActionState(updateProfile, null);
return <form action={formAction}>...</form>;
```

## Streaming & Suspense

```tsx
export default function Dashboard() {
  return (
    <div>
      <Suspense fallback={<AnalyticsSkeleton />}><Analytics /></Suspense>
      <Suspense fallback={<UsersSkeleton />}><Users /></Suspense>
    </div>
  );
}
```

## Performance

- Server Components by default (no JS shipped to browser)
- `reactCompiler: true` in `next.config.ts` — eliminates manual `useMemo`/`useCallback`
- Dynamic imports: `const Heavy = dynamic(() => import('./Heavy'), { loading: ... })`
- `next/image` for automatic image optimization
- `generateMetadata()` for dynamic page metadata

## Security Headers

```typescript
const securityHeaders = [
  { key: "X-Content-Type-Options", value: "nosniff" },
  { key: "X-Frame-Options", value: "DENY" },
  { key: "X-XSS-Protection", value: "0" },
  { key: "Referrer-Policy", value: "strict-origin-when-cross-origin" },
  { key: "Permissions-Policy", value: "camera=(), microphone=(), geolocation=()" },
  { key: "Content-Security-Policy", value: "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self'; connect-src 'self'; frame-ancestors 'none'" },
];
// Apply: async headers() { return [{ source: "/(.*)", headers: securityHeaders }]; }
```

Every app must set `X-Content-Type-Options: nosniff` and `X-Frame-Options: DENY` at minimum.
