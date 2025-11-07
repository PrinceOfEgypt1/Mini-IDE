import net from 'node:net';

export async function checkPortFree(port: number, host = '0.0.0.0'): Promise<boolean> {
  return await new Promise((resolve) => {
    const srv = net.createServer();
    srv.once('error', () => resolve(false));
    srv.once('listening', () => srv.close(() => resolve(true)));
    srv.listen(port, host);
  });
}
