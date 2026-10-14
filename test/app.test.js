import test from 'node:test';
import assert from 'node:assert/strict';
import { normalizeIPs } from '../ip.js';
test('IP validation and deduplication',()=>{assert.equal(normalizeIPs('192.0.2.1\n192.0.2.1 2001:db8::/32'),'192.0.2.1\n2001:db8::/32');for(const invalid of ['example.com','256.1.1.1','1.2.3.4/33','::/129','1.2.3.4/'])assert.throws(()=>normalizeIPs(invalid));});
