package helder.unit.util;

function fixed(num: Float) {
  final precision = 100;
  return  Math.round(num * precision) / precision;
}

function formatDuration(duration: Float) {
  if (duration < 1000) return '${fixed(duration)}ms';
  return '${fixed(duration / 1000)}s';
}
