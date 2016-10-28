
/**
 * cap value between 0 and 1
 */
num cap(num a){
  if (a<0) return 0;
  if (a>1) return 1;
  return a;
}