<?php

defined('BASEPATH') OR exit('No direct script access allowed');

class Lab1_model extends CI_Model {

        public function get_last_entries()
        {
                $query = $this->db->get('lab1', 500);
                return $query->result();
        }

        public function insert_entry($data)
        {
                $this->db->insert('lab1', $data);
        }
}