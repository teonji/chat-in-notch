import { existsSync } from 'node:fs';
import { join } from 'node:path';

// If static/demo.gif exists it replaces the placeholder.
export const load = () => ({
  hasDemo: existsSync(join(process.cwd(), 'static', 'demo.gif'))
});
