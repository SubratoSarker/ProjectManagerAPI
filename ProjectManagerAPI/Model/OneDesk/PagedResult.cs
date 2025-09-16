namespace ProjectManagerAPI.Model.OneDesk
{
    public class PagedResult<T>
    {
        public int Current_Page { get; set; }
        public IEnumerable<T> Data { get; set; } = new List<T>();
        public int Per_Page { get; set; }
        public int Total { get; set; }
        public int Last_Page { get; set; }
        public int From { get; set; }
        public int To { get; set; }
    }
}
