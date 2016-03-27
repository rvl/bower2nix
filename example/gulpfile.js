// gulpfile.js

var gulp = require('gulp');

gulp.task('default', [], function () {
  gulp.start('build');
});

gulp.task('build', [], function () {
  console.log("Just a dummy gulp build");
  gulp
    .src(["./bower_components/**/*"])
    .pipe(gulp.dest("./gulpdist/"));
});
