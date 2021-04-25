package arcane.util;

@:using(arcane.util.Result.ResultUtil)
enum Result<S,F> {
    Success(s:S);
    Failure(f:F);
}

class ResultUtil {
    public function success<S,F>(r:Result<S,F>):S {
        return switch r {
            case Success(s): s;
            case Failure(_): throw "expected success";
        }
    }
}