class ExtendUtil {
    public inline static function last<T>(array:Array<T>):T {
        return array[array.length - 1];
    }

    public inline static function first<T>(array:Array<T>):T {
        return array[0];
    }
}