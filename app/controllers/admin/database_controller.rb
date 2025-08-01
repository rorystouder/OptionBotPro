class Admin::DatabaseController < Admin::BaseController
  def index
    @database_info = get_database_info
    @tables = get_table_list
  end

  def table
    @table_name = params[:table_name]

    # Security: Only allow actual table names
    unless @table_name.in?(get_table_list.keys)
      redirect_to admin_database_path, alert: "Invalid table name"
      return
    end

    @table_info = get_table_info(@table_name)
    @sample_data = get_sample_data(@table_name)
    @row_count = get_row_count(@table_name)
  end

  def schema
    @table_name = params[:table_name]

    unless @table_name.in?(get_table_list.keys)
      redirect_to admin_database_path, alert: "Invalid table name"
      return
    end

    @schema = get_table_schema(@table_name)
    @indexes = get_table_indexes(@table_name)
  end

  def query
    if request.post? && params[:sql].present?
      @sql = params[:sql].strip

      # Security: Only allow SELECT statements for safety
      unless @sql.match?(/\A\s*SELECT\s+/i)
        @error = "Only SELECT queries are allowed for security reasons"
        return
      end

      begin
        @results = execute_query(@sql)
        @execution_time = @results[:execution_time]
        @data = @results[:data]
        @columns = @results[:columns]
      rescue => e
        @error = "Query error: #{e.message}"
      end
    end
  end

  private

  def get_database_info
    db_path = Rails.configuration.database_configuration[Rails.env]["database"]

    file_size = begin
      File.size(db_path)
    rescue
      0
    end

    modified_time = begin
      File.mtime(db_path).strftime("%B %d, %Y at %I:%M %p")
    rescue
      "Unknown"
    end

    {
      path: db_path,
      size: file_size,
      size_human: number_to_human_size(file_size),
      modified: modified_time
    }
  end

  def get_table_list
    tables = {}

    ActiveRecord::Base.connection.tables.each do |table_name|
      begin
        model = table_name.classify.constantize rescue nil
        quoted_table = ActiveRecord::Base.connection.quote_table_name(table_name)
        row_count = ActiveRecord::Base.connection.select_value("SELECT COUNT(*) FROM #{quoted_table}")

        tables[table_name] = {
          model: model,
          row_count: row_count,
          model_name: model ? model.name : "No Model"
        }
      rescue => e
        tables[table_name] = {
          model: nil,
          row_count: 0,
          model_name: "Error"
        }
      end
    end

    tables
  end

  def get_table_info(table_name)
    {
      name: table_name,
      columns: ActiveRecord::Base.connection.columns(table_name).map do |col|
        {
          name: col.name,
          type: col.type,
          sql_type: col.sql_type,
          null: col.null,
          default: col.default,
          primary: col.name == "id" # Simple primary key detection
        }
      end
    }
  end

  def get_sample_data(table_name, limit = 10)
    # Validate table exists first
    return [] unless valid_table_name?(table_name)

    # Use Arel for safe query building
    limit = limit.to_i.clamp(1, 100)
    table = Arel::Table.new(table_name)
    query = table.project(Arel.star).take(limit)

    ActiveRecord::Base.connection.select_all(query)
  end

  def get_row_count(table_name)
    quoted_table = ActiveRecord::Base.connection.quote_table_name(table_name)
    ActiveRecord::Base.connection.select_value("SELECT COUNT(*) FROM #{quoted_table}")
  end

  def get_table_schema(table_name)
    quoted_table = ActiveRecord::Base.connection.quote_table_name(table_name)
    ActiveRecord::Base.connection.select_all("PRAGMA table_info(#{quoted_table})")
  end

  def get_table_indexes(table_name)
    quoted_table = ActiveRecord::Base.connection.quote_table_name(table_name)
    ActiveRecord::Base.connection.select_all("PRAGMA index_list(#{quoted_table})")
  end

  def execute_query(sql)
    start_time = Time.current
    result = ActiveRecord::Base.connection.select_all(sql)
    end_time = Time.current

    {
      data: result.rows,
      columns: result.columns,
      execution_time: ((end_time - start_time) * 1000).round(2) # milliseconds
    }
  end

  def number_to_human_size(size)
    units = [ "B", "KB", "MB", "GB" ]
    unit = 0

    while size >= 1024 && unit < units.length - 1
      size /= 1024.0
      unit += 1
    end

    "#{size.round(1)} #{units[unit]}"
  end

  def valid_table_name?(table_name)
    return false if table_name.blank?
    ActiveRecord::Base.connection.tables.include?(table_name)
  end
end
